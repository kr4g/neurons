(
var fund = 36;

SynthDef(\reverb, {
	var inSig, verb;
	inSig = In.ar(\in.kr(0), 18);
	verb = FreeVerb.ar(inSig, mix: 0.75, room: 0.9, damp: 0.1);
	Out.ar(\out.kr(0), verb);
}).add;

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
	var snd, env, duration, dt, dtRate, freqs, det, lf, bf;
	duration = \dur.kr(1);
	dtRate = \dtRt.kr(0.01);
	det = \detune.kr(0.167.midicps);
	snd = VarSaw.ar([fund, fund + det], width: LFTri.ar(\wdtRate.kr(0.01)).range(0.1,0.9));
	bf = BPF.ar(snd, {SinOsc.ar(ExpRand(0.01, \bpfMaxRate.kr(0.5))).range(fund*2,\lpfFreq.kr(fund*128).lag(0.25))}!8, rq: {SinOsc.ar(freq: ExpRand(0.001, 0.01)).range(0.25,1)}!8);
	snd = bf;
	snd = snd * Env.new(times: [0.5, 0.5], releaseNode: 1).kr(Done.none, \gate.kr(1));
	snd = snd * \amp.kr(-17.dbamp);
	Out.ar(\out.kr(0), snd);
}).add;
)
