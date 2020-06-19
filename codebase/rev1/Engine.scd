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

//Atonal Sampler. Rate control is through zero
SynthDef("samplerAT", {

	/* path is absolute.
	Start and length are in percentage of total. Length longer than 1 will just wrap
	When trig crosses 0, it will restart the sample
	FM is -1 to 1 at audio rate (can be larger, will scale)
	*/

	arg rate = 1, amp = 1, path, start = 0, length = 1, loop = 0, trig = -1 fm=0;

	// check and see if the buffer has already been initialized. If not, instantiate
	if((~sampPath !== path), {~sampBuffer = Buffer.read(s, path); ~sampPath = path}, {});
	//convert positional args to samples
	var loopStart = start * BufFrames.kr(~sampBuffer);
	var loopLength = length * BufFrames.kr(~sampBuffer);
	var loopEnd = sampStart + sampLength;
	//positive rate is forward playback, negative is reversed. +-1 is initial speed
	var loopRate = BufRateScale.kr(~sampBuffer.bufnum) * rate + fm;
	var loopFull = Phasor.ar(trig, loopRate, 0, loopLength);

	var loopWrapped = 0;

	//If loop is true, runs indefinitly.
	if ((loop == 1), {
		BufRd.ar(1, ~sampBuffer, (Wrap((loopFull + loopStart),0, BufFrames.kr(~sampBuffer))), 0, 4);
	},
	{   // else, checks to see if Phasor has reached the end of the buffer, then kills
		while (loopFull < (LoopLength - 1), {
			BufRd.ar(1, ~sampBuffer, (Wrap((loopFull + loopStart),0, BufFrames.kr(~sampBuffer))), 0, 4);

		})
		//
	})
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