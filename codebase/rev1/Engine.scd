// - - - - - INIT - - - - -
( //force synchronous execution for initialization
s = Server.default;
s.boot;

// defined here in the event that they need use later
var serverAddr = "127.0.0.1";
var serverPort = 5551;

// setup server on port 5551
n = NetAddr.new(serverAddr, serverPort);

(
SynthDef("sampler", {
	// path is absolute. Start and length are in percentage of total.
	arg rate = 1, amp = 1, path, start = 0, length, loop = 0, trig = -1, rev = 0, ;

	// check and see if the buffer has already been initialized. If not, instantiate
	if((~sampPath !== path), {~sampBuffer = Buffer.read(s, path)}, {});

	//convert args to sample numbers
	var loopStart = start * BufFrames.kr(~sampBuffer);
	var loopLength = length * BufFrames.kr(~sampBuffer);
	var loopEnd = sampStart + sampLength;
	var loopRate = BufRateScale.kr(~sampBuffer.bufnum) * rate
	var loopPointer = Phasor.ar(trig, , loopStart, loopEnd, loopStart)
	BufRd.ar(1, ~sampBuffer, )
}.add
)
)

// at some point here, the outboard preset manager will read the osc3 controls and send them as OSC messages

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
)