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

b = Buffer.read(s, "Q:/4_Code/Projects/HargroveOld/codebase-new/hargrove-sc/codebase/rev1/wtf.wav");

(
// Atonal Sampler. Rate control is through zero
SynthDef.new(\sampler_atonal, {

	/* Start and length are in percentage of total. Length longer than 1 will just wrap
	When trig crosses 0, it will restart the sample
	When loop is true, the sample loops
	Voice num is a selector from 0 - 8 that sets the output of the synth
	*/

	arg rate = 1, start = 0, length = 1, loop = 0, trig = -1, voiceNum = 0;

	var loopStart, loopLength, loopEnd, loopRate, loopFull, sig, sigMono, sampBuffer, outArr, frames, afa;

	sampBuffer = b;

	//convert positional args to samples
	frames = BufFrames.kr(sampBuffer);
	loopStart = start * frames;
	loopLength = length * frames;
	loopEnd = loopStart + loopLength;
	//positive rate is forward playback, negative is reversed. +-1 is initial speed
	loopRate = BufRateScale.kr(sampBuffer.bufnum) * rate;
	loopFull = Phasor.ar(trig, loopRate, 0, loopLength);
	sig = BufRd.ar(2, sampBuffer, Wrap.ar((loopFull + loopStart),0, frames), 0, 4);
	sigMono = Mix.new(sig);
	outArr = PanAz.ar(8, sigMono, voiceNum/4, 1, 1, 0);
	Out.ar(0, outArr);
	afa = loopFull > (loopLength + (100 * (loop-1)));
	FreeSelf.kr(afa);
}).add;
)

x = Synth.new(\sampler_atonal)
x.set(\loop, 0)

(
SynthDef.new(\test, {
	arg i=0;
	//returns false
	(i==0).postln;
	}
).add;
)
Synth(\test)

x.free;
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









