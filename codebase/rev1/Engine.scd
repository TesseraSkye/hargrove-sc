// - - - - - INIT - - - - -
s.boot;
s.quit;
// // defined here in the event that they need use later
// ~serverAddr = "127.0.0.1";
// ~serverPort = 5551;
//
// // setup server on port 5551
// n = NetAddr.new(~serverAddr, ~serverPort);


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

b = Buffer.read(s, "Q:/4_Code/Projects/HargroveOld/codebase-new/hargrove-sc/codebase/rev1/vocoder.wav");

(
// Atonal Sampler. Rate control is through zero
SynthDef.new(\sampler_atonal, {

	/* Start and length are in percentage of total. Length longer than 1 will just wrap
	When trig crosses 0, it will restart the sample
	When loop is true, the sample loops
	Voice num is a selector from 0 - 8 that sets the output of the synth
	*/

	arg rate = 1, start = 0, duration = 1, loop = 1, trig = -1, voiceNum = 0;

	var loopStart, loopLength, loopEnd, loopRate, loopFull, sig, sigMono, sampBuffer, outArr, frames, freeTrig, deltaTrig;

	sampBuffer = b;

	//convert positional args to samples
	frames = BufFrames.kr(sampBuffer);
	loopStart = start * frames;
	loopLength = duration * frames;
	//positive rate is forward playback, negative is reversed. +-1 is initial speed
	loopRate = BufRateScale.kr(sampBuffer.bufnum) * rate;
	//Positional driver
	loopFull = Phasor.ar(trig, loopRate, 0, loopLength);
	sig = BufRd.ar(2, sampBuffer, Wrap.ar((loopFull + loopStart),0, frames), 0, 4);
	//mix down to mono from whatever config the sample is in
	sigMono = Mix.new(sig);
	outArr = PanAz.ar(8, sigMono, voiceNum/4, 1, 1, 0);
	Out.ar(0, outArr);
	//Here to make live good for debug
	// Out.ar(0, [sigMono,sigMono]);
	//frees self at end if loop is off
	freeTrig = loopFull > (loopLength + (100 * (loop-1)));
	FreeSelf.kr(freeTrig);
}).add;
)

x = Synth(\sampler_atonal);

(
CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=((value-64)/32);
	x.set(\rate, newVal);
	newVal.postln;
}, num:1);

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=(value/128);
	x.set(\start, newVal);
	newVal.postln;
}, num:2);

CCResponder.new({
	arg src, chan, num, value;
	var newVal; newVal=((value/127)**3) + 0.001;
	x.set(\duration, newVal);
	newVal.postln;
}, num:3);
)

CCResponder.responders.do({arg item, index; item.remove;});

(
//Granular Engine
SynthDef.new(\granular, {

	arg path, rate=1, length=1, ktr=1, startPos=0, envPoint=0, envPointX=0, envPointY=0, envPointCurve=0;

	var

	//

	Env
	EnvGen
	EnvelopeView
	GrainBuf
	PathName




	(
// use shift-click to keep a node selected
w = Window("envelope", Rect(150 , Window.screenBounds.height - 250, 250, 100)).front;
w.view.decorator = FlowLayout(w.view.bounds);

b = EnvelopeView(w, Rect(0, 0, 230, 80))
    .drawLines_(true)
    .selectionColor_(Color.blue)
    .drawRects_(true)
    .resize_(20)
    .step_(0.05)
    .action_({arg b; [b.index, b.value].postln})
    .thumbSize_(20)
    .value_([[0.0, 0.1, 0.5, 1.0],[0.1,1.0,0.8,0.0]]);
w.front;
)


}).add
)


// at some point here, the outboard preset manager will read the osc3 controls and send them as OSC messages









