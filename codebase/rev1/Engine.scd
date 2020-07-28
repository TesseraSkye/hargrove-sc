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

//controls for sampler
(
CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=((value-63.5)/31.75);
	x.set(\rate, newVal);
	// newVal.postln;
}, num:1);

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	x.set(\start, newVal);
	// newVal.postln;
}, num:2);

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=((value/127)**3);
	x.set(\duration, newVal);
	// newVal.postln;
}, num:3);
NoteOnResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=2**((num/12)-5);
	x.set(\ratioPitch, newVal);
	// newVal.postln;
	});

//controls for granular

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=((value)/15.875);
	g.set(\grainRate, newVal);
	// newVal.postln;
}, num:1);

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/15.875);
	g.set(\density, newVal);
	// newVal.postln;
}, num:2);

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	g.set(\startPos, newVal);
	// newVal.postln;
}, num:3);
NoteOnResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=2**((num/12)-5);
	g.set(\ratioPitch, newVal);
	// newVal.postln;
});

//controls for resonator
CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	r.set(\fOffset, newVal);
	// newVal.postln;
}, num:1);

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	r.set(\dScale, newVal);
	// newVal.postln;
}, num:2);

/*CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	r.set(\startPos, newVal);
	// newVal.postln;
}, num:3);*/
NoteOnResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=2**((num/12)-5);
	r.set(\ratioPitch, newVal);
	// newVal.postln;
});

//controls for bass
CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	s.set(\paramX, newVal);
	// newVal.postln;
}, num:1);

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	s.set(\paramY, newVal);
	// newVal.postln;
}, num:2);

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	s.set(\paramZ, newVal);
	// newVal.postln;
}, num:3);
NoteOnResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=num.midicps;
	s.set(\cpsPitch, newVal);
	// newVal.postln;
});

//controls for tube
CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	t.set(\paramX, newVal);
	// newVal.postln;
}, num:1);

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	t.set(\paramY, newVal);
	// newVal.postln;
}, num:2);

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/127);
	t.set(\paramZ, newVal);
	// newVal.postln;
}, num:3);
NoteOnResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=num.midicps;
	t.set(\cpsPitch, newVal);
	// newVal.postln;
});
)
//!!!!!!!P I T C H   I S  2^((MIDI / 12) - 5)


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

	arg sampBuffer, rate = 1, start = 0, duration = 1, loop = 0, trig = -1, voiceNum = 0, ratioPitch=0;

	var loopStart, loopLength, loopEnd, loopRate, loopPos, sig, sigMono, outArr, frames, freeTrig, deltaTrig;

	//prevents overflow or underflow
	duration = duration.clip(0.001,1);
	//convert positional args to samples
	frames = BufFrames.kr(sampBuffer);
	loopStart = start * frames;
	loopLength = duration * frames;
	loopLength = loopLength.clip(128,loopLength+20);
	//positive rate is forward playback, negative is reversed. +-1 is initial speed
	loopRate = BufRateScale.kr(sampBuffer) * (rate + ratioPitch);
	//Positional driver
	loopPos = Phasor.ar(trig, loopRate, 0, loopLength);
	sig = BufRd.ar(1, sampBuffer, Wrap.ar((loopPos + loopStart),0, frames), 0, 4);
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

// x = Synth(\sampler, ["loop",1,'sampBuffer',b]);



(
//Granular Engine
SynthDef.new(\granular, {

	// grain rate is grains / second (kinda), density is ratio of grain rate : grain length
	arg sampBuffer, env, grainRate=0, density=1, ratioPitch=1, startPos=0, ktr=1, voiceNum=0;

	var grainTrig, duration, frames, sig, outArr;

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

// g = Synth(\granular, [\sampBuffer,b,\env,-1,\grainRate,7,\density,1,\ratioPitch,1,\startPos,0.2]);

(
//modal synthesis
SynthDef.new(\resonator, {
	arg input, ratioPitch=1, fOffset=0, dScale=1,
    freqs (#[261.63, 523.26, 1048, 2096]),
    amps (#[0.8, 0.6, 0.4, 0.05]),
	rings (#[2, 1.5, 2, 0.8]);
	var sig;
	fOffset = 600*(2**(fOffset))-600;
	sig = DynKlank.ar(`[freqs, amps, rings], input.asAudioRateInput, ratioPitch, fOffset, dScale);
    Out.ar(0, sig);
}).add;
)

r = Synth(\resonator);
r.set(\fOffset, 2)



(
//osc patch for heavy bass design
SynthDef.new(\bass, {
	arg cpsPitch = 55, paramX=0, paramY=0, paramZ=0;
	var sig, sin, tri, saw, modSaw, pulse, wNoise, freqs, amps, rings;
	sin = SinOsc.ar(cpsPitch);
	tri = LFTri.ar(cpsPitch);
	modSaw = Saw.ar(cpsPitch);
	saw = Saw.ar(cpsPitch/*, cpsPitch*(paramX+1)*/);
	wNoise = WhiteNoise.ar;

	sig = saw;

	// sig = BPF.ar(sig,100);

	/*freqs = (#[261.63, 523.26, 1048, 2096]);
	amps = (#[0.8, 0.6, 0.4, 0.05]);
	rings = (#[2, 1.5, 2, 0.8]);
	sig = DynKlank.ar(`[freqs, amps, rings], sig*0.01);*/

	sig = NTube.ar(sig,`[0.97,1.0,1.0,1.0,1.0,0.97],`[0.3,paramX-0.1,0.5,-0.4],`([0.01,0.02,0.01,0.005,0.05]*(paramY)))*0.1;

	/*sig = InsideOut.ar(sig);
	sig = LPF.ar(sig,(paramY*127).midicps);
	sig = SineShaper.ar(sig, 0.5);

	sig = LeakDC.ar(sig);
	sig = CombC.ar(sig,0.2, 1/(cpsPitch*(2**(paramZ*4))),0.1);
	sig = Decimator.ar(sig, cpsPitch*(2**(paramY*10)));
*/
	Out.ar(0, [sig,sig]);
}).add;
)

s = Synth(\bass);

(
//hammer tube thing. idk, it's cool lol
SynthDef.new(\tube, {
	arg cpsPitch = 55, paramX=0, paramY=0, paramZ=0;
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

t = Synth(\tube);

// at some point here, the outboard preset manager will read the osc3 controls and send them as OSC messages


