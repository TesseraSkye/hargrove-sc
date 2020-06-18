s = Server.default;
s.boot;

n = NetAddr.new("127.0.0.1", 5551);



/*
OSC3 Modes
0 - Sample Playback
1 - Wavetable (VOsc)
2 - Granular
3 - Digital Oscilators
4 - Spring
5 - Resonators
*/

var setOsc3Mode;
setOsc3Mode = {
	arg mode;
	~osc3Mode = mode;
};

// sets osc mode to Sample at startup. Will be updated with getHWData
setOsc3Mode.value(0);
