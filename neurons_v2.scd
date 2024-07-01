/*
"PROTONOESIS 1"
*/

// 0a. Init Server
(
Server.killAll;
Buffer.freeAll;
s = Server.local;
// ServerOptions.devices;
s.options.outDevice_(
	"MacBook Pro Speakers"
	// "External Headphones"
	// "Scarlett 4i4 USB"
	// "MME : Out 1-24 (MOTU Pro Audio)"
);
s.options.inDevice_("Built-in Microph");
s.options.numOutputBusChannels_(18);
s.options.numInputBusChannels_(0);
s.options.sampleRate_(48000);
s.options.memSize_(2.pow(20));
s.reboot;
)

// 0b. Get project path
~projectPath = PathName.new(thisProcess.nowExecutingPath).parentPath;

// 1. SynthDefs
(~projectPath ++ "synthdefs.scd").load;

// 2a. Load buffers (this may take a minute)
(~projectPath ++ "loadbuffers.scd").load;

// 2b. Sanity checks
(
Routine({
	("Labels size:     " ++ ~labels.size).postln;   // 131
	("Rates size:      " ++ ~rates.size).postln;    // (131, 180000)
	("Spikes size:     " ++ ~spikes.size).postln;   // (131, 180000)
	("Density size:    " ++ ~density.size).postln;  // 180000
	("Avg. Rates size: " ++ ~avgRates.size).postln; // 180000
}).play;
)

// 2c. Free buffers
Buffer.freeAll;

// 3. Playback and interaction function(s)
(
~playNeurons = {
	arg index = 0;
	var density = ~density[index];
	var avgRate = ~avgRates[index];
	var weights = [2+density,5,3+density].normalizeSum;
	NetAddr("192.168.50.253", 10000).sendMsg("/avgRate", avgRate);
	NetAddr("192.168.50.253", 10000).sendMsg("/density", density);
	// NetAddr("192.168.50.24", 10000).sendMsg("/avgRate", avgRate);
	// NetAddr("192.168.50.24", 10000).sendMsg("/density", density);
	s.bind { ~droneSynth.set(\lpfFreq, density.linexp(0,1,8000,200), \amp, density.linlin(0,1,-2.dbamp,-28.dbamp)); };
	131.do { |j|
		if ( ~spikes[j][index] * (1.0 - ~labels[j]) > 0.0,
			{
				var val = linlin(~rates[j][index], 0, 1, 3.4375, 27.5);
				var scale = linlin(~rates[j][index], 0, 1, exprand(1, avgRate.linlin(0,1,5,2)), 0.5);
				var amp = density.linexp(0, 1, -2.dbamp, -9.dbamp);
				var synth = [\neuron1, \neuron2, \neuron3].wchoose(weights);
				var freq = ~rates[j][index].linlin(0,1,36,linexp(density,0,1,2304,4608));
				var out;
				if (freq < 576,
					{
						if (freq < 108,
							{out = rrand(16,17)},
							{out = rrand(0,15)}
						);
					},
					{
						out = rrand(8,15);
						if (freq > 3000,
							{
								("Neuron " ++ j.asString ++ " at maximum rate, " ++ (~rates[j][index]).asString ++ " Hz").postln;
							}
						);
					}
				);
				s.bind { Synth(synth, [
					\ampRate, val,
					\dur, density.linlin(0,1,1,2)*scale,
					\freq, freq,
					\amp, amp,
					\out, out
				]); };
			},
			{}
		);
	};
	if ( density > 0.1,
		{ s.bind { ~droneSynth.set(\bpfMaxRate, exprand(0.001,0.1+avgRate), \wdtRate, avgRate.linexp(0,1,0.001,0.1+density)); }; }
	);
	if ( density > 0.6,
		{
			("Neural Density: " ++ density.asString ++ ", " ++ index.asString ++ " ms").postln;
			if ( density > 0.7,
				{("Critical Spike Activity: " ++ index.asString ++ " ms").postln;}
			);
		},
	);
}
)

// 4. Open UDP Ports
(
thisProcess.openUDPPort(2345);
thisProcess.openUDPPort(1234);
thisProcess.openPorts;
)

// 5. Activate
(
s.bind { ~fx = Synth.tail(nil, \reverb); };
s.bind { ~droneSynth = Synth(\drone, [\amp, -8.dbamp]); };

OSCdef(\receiver, {
	arg msg;
	var idx = msg[1];
	// idx.postln;
	~playNeurons.(idx);
}, '/index')
)


// TEST
(
Routine({
	var fx;
	s.bind { fx = Synth.tail(nil, \reverb); };
	s.bind { ~droneSynth = Synth(\drone, [\amp, -8.dbamp]); };
	180000.do { |i|
		~playNeurons.(i);
		(32/1000).wait;
	};
	s.bind { ~droneSynth.set(\gate, 0); };
	s.bind { fx.free; ~droneSynth.free};
}).play;
)

// (
// Routine({
// 	180000.do { |i|
// 		var density = ~density[i];
// 		var avgRate = ~avgRates[i];
// 		// i.postln;
// 		NetAddr("192.168.50.253", 10000).sendMsg("/avgRate", avgRate);
// 		NetAddr("192.168.50.253", 10000).sendMsg("/density", density);
// 		NetAddr("192.168.50.138", 10000).sendMsg("/avgRate", avgRate);
// 		NetAddr("192.168.50.138", 10000).sendMsg("/density", density);
// 		(32/1000).wait;
// 	};
// }).play;
// )
