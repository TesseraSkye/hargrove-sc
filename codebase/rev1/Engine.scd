// - - - - - INIT - - - - -
s.boot;
s.quit;
// // defined here in the event that they need use later
// ~serverAddr = "127.0.0.1";
// ~serverPort = 5551;
//
// // setup server on port 5551
// n = NetAddr.new(~serverAddr, ~serverPort);

// C O N T R O L S

//reset controls
(
CCResponder.responders.do({arg item, index; item.remove;});
NoteOnResponder.responders.do({arg item, index; item.remove;});
)

(
CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	~synth.set(\paramX, newVal);
	// newVal.postln;
}, num:1);

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	~synth.set(\paramY, newVal);
	// newVal.postln;
}, num:2);

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	~synth.set(\paramZ, newVal);
	// newVal.postln;
}, num:3);
NoteOnResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=num.midicps;
	~synth.set(\cpsPitch, newVal);
	// newVal.postln;
});
)






//!!!!!!!R A T I O   P I T C H   I S  2**((cpsPitch.cpsmidi / 12) - 5)


/*
OSC3 Modes
0 - Sample Playback (PlayBuf) (low rate, osc rate) (Wrap)
1 - 3D Wavetable (VOsc) (allows recording)
2 - Granular (GrainBuf) (trig, dur, rate, pos)
3 - Digital Oscilators (Osc) - Saw, sine, tri, pulse, supersaw, etc. Can be shaped with (Shaper)
4 - Analog Sampled Oscillators - sampled from internal (VOsc ? maybe just Osc) Can be shaped with (Shaper)
5 - Spring (Spring) - Spring Synthesis
6 - Resonators (DynKlank) - Bank modal resonator
7 - Pluck (Pluck) - Karplus Pluck (variable source)
*/


~sampPath = "Q:/4_Code/Projects/HargroveOld/codebase-new/hargrove-sc/codebase/rev1/samples/vocoder.wav";
b = Buffer.readChannel(s, ~sampPath,channels:[0]);


b.free;

(
// Atonal Sampler. Rate control is through zero
SynthDef.new(\sampler, {

	/* Start and length are in percentage of total. Length longer than 1 will just wrap
	When trig crosses 0, it will restart the sample
	When loop is true, the sample loops
	Voice num is a selector from 0 - 8 that sets the output of the synth
	*/

	arg sampBuffer, paramX = 0, paramY = 0, paramZ = 1, cpsPitch=440, loop = 0, trig = -1, voiceNum = 0;

	var loopStart, loopLength, loopEnd, loopRate, loopPos, sig, sigMono, outArr, frames, freeTrig, deltaTrig, ratioPitch, rate, start, duration;

	rate = (paramX-0.5)*4;
	start = paramY;
	duration = paramZ**3;
	ratioPitch = 2**((cpsPitch.cpsmidi / 12) - 5);

	//prevents overflow or underflow
	duration = duration.clip(0.001,1);
	//convert positional args to samples
	frames = BufFrames.kr(sampBuffer);
	deltaTrig = Changed.ar(LeakDC.ar(start.asAudioRateInput),0);
	deltaTrig = Trig1.ar(deltaTrig,0.25);
	deltaTrig = deltaTrig * (0-1) + 1;
	// deltaTrig.poll(20,deltaTrig);
	loopStart = start * frames;
	loopLength = duration * frames;
	loopLength = loopLength.clip(128,loopLength+20);
	//positive rate is forward playback, negative is reversed. +-1 is initial speed
	loopRate = BufRateScale.kr(sampBuffer) * (rate + ratioPitch);
	//Positional driver
	loopPos = Phasor.ar(trig, loopRate, 0, loopLength);
	sig = BufRd.ar(1, sampBuffer, Wrap.ar((loopPos + loopStart)*deltaTrig,0, frames), 0, 4);
	//set up panning to all 8 outputs
	outArr = PanAz.ar(8, sig, voiceNum/4, 1, 1, 0);
	Out.ar(0, outArr);
	//Here to make life good for debug
	// Out.ar(0, [sig,sig]);
	//frees self at end if loop is off
	freeTrig = loopPos > (loopLength - 100 + (1000 * (loop)));
	FreeSelf.kr(freeTrig);
}).add;
)

~synth = Synth(\sampler, ["loop",1,'sampBuffer',b]);



(
//Granular Engine
SynthDef.new(\granular, {

	// grain rate is grains / second (kinda), density is ratio of grain rate : grain length
	arg sampBuffer, paramX=0, paramY=1, paramZ=0, cpsPitch=440, env= -1, ktr=1, voiceNum=0;

	var grainTrig, duration, frames, sig, outArr, grainRate, density, startPos, ratioPitch;

	grainRate = paramX*8;
	density = paramY*8;
	startPos = paramZ;
	ratioPitch = 2**((cpsPitch.cpsmidi / 12) - 5);

	//scales the vales from 0
	grainRate = 2**grainRate;

	duration = density/grainRate;

	grainTrig = Impulse.ar(grainRate);

	sig = GrainBuf.ar(1, grainTrig, duration, sampBuffer, ratioPitch, startPos, envbufnum:env, maxGrains:512);

	outArr = PanAz.ar(8, sig, voiceNum/4, 1, 1, 0);
	Out.ar(0, outArr);
	}
).add;

)

~synth = Synth(\granular, [\sampBuffer,b,\env,-1,\grainRate,7,\density,1,\ratioPitch,1,\startPos,0.2]);




(
//modal synthesis
SynthDef.new(\resonator, {
	arg input, cpsPitch=440, paramX=0, paramY=1, paramZ=0,
    freqs (#[261.63, 523.26, 1048, 2096]),
    amps (#[0.8, 0.6, 0.4, 0.05]),
	rings (#[2, 1.5, 2, 0.8]);
	var sig, fOffset, dScale, ratioPitch;

	fOffset = paramX;
	dScale = paramY;
	ratioPitch = 2**((cpsPitch.cpsmidi / 12) - 5);

	fOffset = 600*(2**(fOffset))-600;
	sig = DynKlank.ar(`[freqs, amps, rings], input.asAudioRateInput, ratioPitch, fOffset, dScale);
    Out.ar(0, sig);
}).add;
)

~synth = Synth(\resonator);
~synth.set(\fOffset, 2)


(
//hammer tube thing. idk, it's cool lol
SynthDef.new(\tube, {
	arg cpsPitch = 440, paramX=0, paramY=0, paramZ=0;
	var sig, saw, modSaw;
	modSaw = Saw.ar(cpsPitch/(2**2));
	saw = Saw.ar(cpsPitch);

	sig = saw;

	sig = NTube.ar(sig,`[0.97,1.0,1.0,1.0,1.0,0.97],`[0.3,paramX-0.1,modSaw*paramZ,-0.4],`([0.01,0.02,0.01,0.005,0.05]*(paramY)))*0.1;
	sig = SineShaper.ar(sig, 0.5);

	sig = CombC.ar(sig,0.2, 1/(cpsPitch*(2**(paramZ*4))),0.1);
	sig = LeakDC.ar(sig);

	Out.ar(0, [sig,sig]);
}).add;
)

~synth = Synth(\tube);



// Wavetable Prep

(
"".postln;
~frameSize = 2048;
~wtPath = "Q:/4_Code/Projects/HargroveOld/codebase-new/hargrove-sc/codebase/rev1/samples/wt_shapes.wav";
~tables = [];
~wtBufferFull = Buffer.read(s, ~wtPath);
"Wavetable Build Started...".postln;
)

(
"".postln;
//get frames in wavetable
~tableSamps = ~wtBufferFull.numFrames;
	// ~tableSamps.postln;
~tableFrames = ~tableSamps/~frameSize;

//makes wavetable out of buffer

~buildWavetable = {
	arg buf, tableNum, frameSize;
	var floatArr, sig, frameOffset, outBuff;
	// frameSize.postln;
	// tableNum.postln;

	// build frame offset from
	frameOffset = ((tableNum * frameSize)-1).clip(0,255*frameSize);
	// frameOffset.postln;

	//builds float array from buffer
	buf.getToFloatArray(frameOffset, frameSize, action:{arg array; {
		floatArr = array;
		// floatArr.postln;

		//converts float array to signal
		sig = Signal.newClear(frameSize).waveFill({ |x, old, i| floatArr[x]},0,frameSize);

		//to wavetable format
		sig = sig.asWavetable;
		// sig.postln;

		// send collection streams an array (this time it's a signal) to the server and into a new buffer.
		//this is global because stepping up doesn't work. :shrug:
		~localOutBuff = Buffer.sendCollection(s,sig);

		//free the signal and array
		floatArr.free;
		sig.free;
	}.defer;});
	~localOutBuff;
};
"Registered Wavetable Build Function...".postln;
)

// addsWavetables

//init table array
(
"".postln;
"Allocating Table Space...".postln;
~tables = Array.newClear(~tableFrames);
// repeats once for each table
"Building Tables...".postln;
~tables.do({
	arg data, num;
	// num.postln;
	// done twice to fix weird bug
	fork {
		//forces the execution to wait so there aren't overlaps
		(num).wait;
		AppClock.sched(0, {(~buildWavetable.value(~wtBufferFull, num, ~frameSize)).free;});
		AppClock.sched(0.05, {~tables.put(num,~buildWavetable.value(~wtBufferFull, num, ~frameSize);)});
		("Built table" + num).postln;
	};
});
)


/*~tables.put(0,~buildWavetable.value(~wtBufferFull, 0, ~frameSize);)
~tables = Array.newClear(~tableFrames);
~tables.postln;
~tables[0].plot;*/


(
SynthDef.new(\wavetable, {
	arg buffer, rate=0, cpsPitch=110, frameSize = 2048, paramX=0, paramY=0, paramZ=0, frameCount = 1;
	var sig;
	sig = Osc.ar(buffer,cpsPitch);

	sig.scope;
	Out.ar(0, [sig,sig]);
}).add;
)
~synth = Synth(\wavetable, [\buffer,e]);
// ~synth.set(\frameSize,1024);
~synth.set(\paramX, (2));



/*(
//osc patch for heavy bass design
SynthDef.new(\bass, {
	arg cpsPitch = 100, paramX=0, paramY=0, paramZ=0;
	var sig, sin, tri, saw, pulse, wNoise, freqs, amps, rings, mod, modSource;

	VOsc.ar

	modSource = SinOsc.ar(cpsPitch*(2**(3*paramY)));

	mod = modSource + 1;
	mod = mod*cpsPitch*paramX*4;

	sin = SinOsc.ar(cpsPitch + mod);
	tri = LFTri.ar(cpsPitch + mod);
	saw = LFSaw.ar(cpsPitch + mod);
	wNoise = WhiteNoise.ar;

	sig = saw;

	sig = CombC.ar(sig,0.2, 1/(cpsPitch*(2**(paramY*4))),0.1);

	// sig = BPF.ar(sig,100);

	// sig = InsideOut.ar(sig);
	// sig = LPF.ar(sig,(paramY*127).midicps);
	// sig = SineShaper.ar(sig, 0.5);
	//
	// sig = LeakDC.ar(sig);
	// sig = Decimator.ar(sig, cpsPitch*(2**(paramY*10)));

	Out.ar(0, [sig,sig]);
}).add;
)*/

// p = Synth(\bass);


// at some point here, the outboard preset manager will read the osc3 controls and send them as OSC messages


