(
s = Server.local;
// ServerOptions.devices;
s.options.outDevice_(
	// "MacBook Pro Speakers"
	"External Headphones"
	// "Scarlett 4i4 USB"
);
s.options.inDevice_("Built-in Microph");
s.options.numOutputBusChannels_(2);
s.options.numInputBusChannels_(2);
s.options.sampleRate_(48000);
s.options.memSize_(2.pow(20));
s.reboot;
)

"/Users/ryanmillett/MAT276IA/allolib_playground/AlloPy/examples/synthdefs.scd".load;

(

var fund = 36;

SynthDef(\reverb, {
	var inSig, verb;
	inSig = In.ar(\in.kr(0), 2);
	verb = FreeVerb2.ar(inSig[0], inSig[1], mix: 0.85, room: 0.8, damp: 0.1);
	verb = Splay.ar(verb);
	Out.ar(\out.kr(0), verb);
}).add;

// SynthDef(\delay, {
// 	var sig;
// 	sig = In.ar(\in.kr(0), 2);
// 	sig = CombC.ar(sig);
// 	Out.ar(\out.kr(0), sig);
// }).add;

SynthDef(\neuron1, {
	var snd, am, amRate, duration, wdth, maxFormHz, maxRezHz;
	duration = \dur.kr(0.5);
	amRate = \ampRate.kr(5);
	wdth = LinRand(0.0, 1.0);
	maxFormHz = 1760;
	maxRezHz = 880;
	snd = Formant.ar(fund, XLine.ar(55, ExpRand(110, maxFormHz), duration), XLine.ar(27.5, ExpRand(27.5, maxRezHz), duration));
	am = VarSaw.ar(freq: amRate, width: wdth).range(0, 1);
	snd = snd * am;
	// snd = CombC.ar(snd, decaytime: duration);
	snd = snd * Env.perc(duration, \rel.kr(0), 1.0, 32).kr(Done.freeSelf);
	snd = snd * \amp.kr(-34.dbamp);
	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\neuron2, {
	var snd, duration;
	// duration = \dur.kr(1);
	snd = SinOsc.ar(\freq.kr(880));
	snd = snd * Env.perc(0, 0.1, 1.0, curve: -32).kr(Done.freeSelf);
	snd = snd * \amp.kr(-23.dbamp);
	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\neuron3, {
	var snd, duration;
	duration = \dur.kr(5);
	snd = Pulse.ar(\freq.kr(fund), width: 0.5);
	snd = BPF.ar(snd, ExpRand(\minFreq.kr(220), 1760*4), rq: ExpRand(0.25, 0.75));
	snd = snd * Env.perc(duration, 0, 1.0, curve: 128).kr(Done.freeSelf);
	snd = snd * \amp.kr(-23.dbamp);
	Out.ar(\out.kr(0), snd);
}).add;

SynthDef(\drone, {
	var snd, env, duration, dt, dtRate;
	duration = \dur.kr(1);
	dtRate = \dtRt.kr(0.01);
	dt = SinOsc.kr(dtRate).range(0.16.midicps, \detune.kr(0.67.midicps));
	snd = VarSaw.ar([fund, fund-dt]*2, width: SinOsc.kr(\wdtRate.kr(0.1)).range(0.1,0.9));
	// env = Env.asr(duration, 1, 0, curve: -8).kr(Done.freeSelf);
	// snd = LPF.ar(snd, LFTri.ar(SinOsc.kr(0.5).range(0.1, 3.4375)).range(110, 3520));
	// snd = LPF.ar(snd, SinOsc.kr(SinOsc.kr(0.05).range(0.1, 3.4375*2)).range(220, 1760*4));
	snd = LPF.ar(snd, \lpfFreq.kr(500));
	// snd = snd * env;
	snd = snd * \amp.kr(-17.dbamp);
	Out.ar(\out.kr(0), snd);
}).add;
)

x = Synth.tail(nil, \reverb);
x.free;

~droneSynth = Synth(\drone, [\dur, 5, \amp, -28.dbamp]);
~droneSynth.free;

(
Synth(\drone, [\dur, 5, \amp, -32.dbamp]);
Routine({
	inf.do {
		Synth(\neuron1, [\amp, -19.dbamp, \dur, exprand(1,8), \freq, exprand(55,880)]);
		Synth(\neuron2, [\amp, -11.dbamp, \dur, exprand(0.05,0.5), \freq, exprand(55,880)]);
		Synth(\neuron3, [\amp, -7.dbamp, \dur, exprand(0.1,5), \minFreq, exprand(55,880)]);
		exprand(0.05,5).wait;
	}
}).play;
)

(
~rates = [];
~spikes = [];
131.do{ |i|
	var n_id = i.asString.padLeft(3, "0");
	b = Buffer.read(server: s, path: "/Users/ryanmillett/Downloads/csvWavFiles/rates_norm_" ++ n_id ++ ".wav");
	c = Buffer.read(server: s, path: "/Users/ryanmillett/Downloads/csvWavFiles/t_spk_mat_" ++ n_id ++ ".wav");

	b.loadToFloatArray(action: { |array|
		var indices = (0..180000-1);
		~rates = ~rates.add(indices.collect { |n| array[n] });
	});

	c.loadToFloatArray(action: { |array|
		var indices = (0..180000-1);
		~spikes = ~spikes.add(indices.collect { |n| array[n] });
	});
}
)
(
~labels = [];
d = Buffer.read(server: s, path: "/Users/ryanmillett/Downloads/neuron_labels.wav");
d.loadToFloatArray(action: { |array|
	~labels = array;
});
)
~labels.size;

Buffer.freeAll;

~rates.size;
~spikes.size;

~density = [];
(
e = Buffer.read(server: s, path: "/Users/ryanmillett/Downloads/simul_spikes.wav");
e.loadToFloatArray(action: { |array|
	~density = array;
});
)

thisProcess.openUDPPort(2345);
thisProcess.openUDPPort(1234);
thisProcess.openPorts;

~density.size;

(
~playNeurons = {
	arg index = 0;
	var density = ~density[index];
	// density.postln;
	~droneSynth.set(\lpfFreq, density.linlin(0,1,8000,200), \amp, density.linlin(0,1,-21.dbamp,-46.dbamp), \wdtRate, density.linexp(0,1,exprand(0.005,density + 0.3),exprand(13.75, 27.5)));
	131.do { |j|
		// var activation = ~spikes[j][index];
		if ( ~spikes[j][index] * (1.0 - ~labels[j]) > 0.0,
			{
				var val = linlin(~rates[j][index], 0, 1, 13.75/4, 27.5);
				// var density = ~density[index];
				var scale = linlin(~rates[j][index], 0, 1, exprand(1, 8), 0.5);
				var amp = density.linexp(0, 1, -1.dbamp, -28.dbamp);
				// density.postln;
				var synth = [\neuron1, \neuron1, \neuron2, \neuron2, \neuron3].choose;
				// ~labels[j].postln;
				s.bind { Synth(synth, [
					\ampRate, val,
					\dur, density.linlin(0,1,1,2)*scale,
					\freq, exprand(55,880*4),
					\amp, amp,
				]); };
				~droneSynth.set(\dtRt, density.linexp(0,1,0.01,3), \detune, rrand(0.33.midicps, 0.833.midicps));
			},
			{}
		);
	};
	// index.postln;
}
)

~playNeurons.(122);

f = Synth.tail(nil, \reverb);
f.free;

(
// f = Synth.tail(nil, \reverb);
OSCdef(\receiver, {
	arg msg;
	var idx = msg[1];
	// idx.postln;
	~playNeurons.(idx);
}, '/index')
)

(
Routine({
	var fx;
	s.bind{ fx = Synth.tail(nil, \reverb); };
	~droneSynth = Synth(\drone, [\dur, 5, \amp, -28.dbamp]);
	180000.do { |i|
		~playNeurons.(i);
		// (1/100).wait;
		(32/1000).wait;
	};
}).play;
)

(
SynthDef(\pinkNoise, {
	arg out = 0;
	var sound = PinkNoise.ar(-8.dbamp);
	Out.ar(out, sound);
}).add;
)

n = Synth(\pinkNoise);
n.set(\out, 0);
n.free;

noiseSynth.free;
(
var noiseSynth = Synth(\pinkNoise);
Routine({
	1.do { |i|
		noiseSynth.set(\out, i);
		1.wait;
	}
}).play;
)