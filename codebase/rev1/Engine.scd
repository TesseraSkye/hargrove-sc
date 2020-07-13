// - - - - - INIT - - - - -
s.boot;

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


(
//Atonal Sampler. Rate control is through zero
SynthDef.new(\sampler_atonal, {

	/* path is absolute.
	Start and length are in percentage of total. Length longer than 1 will just wrap
	When trig crosses 0, it will restart the sample
	FM is -1 to 1 at audio rate (can be larger, will scale)
	*/

	arg rate = 1, path, start = 0, length = 1, loop = 0, trig = -1;

	var loopStart, loopLength, loopEnd, loopRate, loopFull, sig;

	// check and see if the buffer has already been initialized. If not, instantiate
	if((~sampPath !== path),
		{
			~sampBuffer = Buffer.read(s, path);
			~sampPath = path;
			~sampPath.postln;},
		{~sampPath.postln;});
	//convert positional args to samples
	loopStart = start * BufFrames.kr(~sampBuffer);
	loopLength = length * BufFrames.kr(~sampBuffer);
	loopEnd = loopStart + loopLength;
	//positive rate is forward playback, negative is reversed. +-1 is initial speed
	loopRate = BufRateScale.kr(~sampBuffer.bufnum) * rate + fm;
	loopFull = Phasor.ar(trig, loopRate, 0, loopLength);
	sig = BufRd.ar(1, ~sampBuffer, (Wrap((loopFull + loopStart),0, BufFrames.kr(~sampBuffer))), 0, 4);
	//If loop is false, kills at end of cycle
	if ((loop == 0), {
		FreeSelf(loopFull.value - (loopLength - 1))
	},
	{});

	Out.ar(0, sig);
}
).add;
)

x = Synth.new(\sampler_atonal, [\path, "wtf.wav"]);



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









