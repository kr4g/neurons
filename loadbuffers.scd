(
var projectPath = PathName.new(thisProcess.nowExecutingPath).parentPath;
~rates = [];
~spikes = [];
131.do{ |i|
	var n_id = i.asString.padLeft(3, "0");
	b = Buffer.read(server: s, path: projectPath ++ "csvWavFiles/rates_norm_" ++ n_id ++ ".wav");
	b.loadToFloatArray(action: { |array|
		var indices = (0..180000-1);
		~rates = ~rates.add(indices.collect { |n| array[n]; /*{~rates.size.postln}.defer;*/ });
	});

	c = Buffer.read(server: s, path: projectPath ++ "csvWavFiles/t_spk_mat_" ++ n_id ++ ".wav");
	c.loadToFloatArray(action: { |array|
		var indices = (0..180000-1);
		~spikes = ~spikes.add(indices.collect { |n| array[n]; /*{~spikes.size.postln}.defer;*/ });
	});
};

~labels = [];
d = Buffer.read(server: s, path: projectPath ++ "neuron_labels.wav");
d.loadToFloatArray(action: { |array| ~labels = array; /*{~labels.size.postln}.defer;*/ });

~density = [];
e = Buffer.read(server: s, path: projectPath ++ "simul_spikes.wav");
e.loadToFloatArray(action: { |array| ~density = array; /*{~density.size.postln}.defer;*/ });

~avgRates = [];
g = Buffer.read(server: s, path: projectPath ++ "avg_rates.wav");
g.loadToFloatArray(action: { |array| ~avgRates = array; /*{~avgRates.size.postln}.defer;*/ });

// "Done".postln;
)
