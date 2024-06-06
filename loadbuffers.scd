(
~rates = [];
~spikes = [];
131.do{ |i|
	var n_id = i.asString.padLeft(3, "0");
	b = Buffer.read(server: s, path: "C:\\Users\\transTeam\\Desktop\\NoidSound\\MaxPatches\\backBoners\\normedNoidWaves\\rates_norm_" ++ n_id ++ ".wav");
	c = Buffer.read(server: s, path: "C:\\Users\\transTeam\\Desktop\\NoidSound\\MaxPatches\\backBoners\\noidSpikes\\t_spk_mat_" ++ n_id ++ ".wav");

	b.loadToFloatArray(action: { |array|
		var indices = (0..180000-1);
		~rates = ~rates.add(indices.collect { |n| array[n] });
	});

	c.loadToFloatArray(action: { |array|
		var indices = (0..180000-1);
		~spikes = ~spikes.add(indices.collect { |n| array[n] });
	});
};

~labels = [];
d = Buffer.read(server: s, path: "C:\\Users\\transTeam\\Desktop\\neurons-main\\neurons-main\\neuron_labels.wav");
d.loadToFloatArray(action: { |array|
	~labels = array;
});

~density = [];
e = Buffer.read(server: s, path: "C:\\Users\\transTeam\\Desktop\\neurons-main\\neurons-main\\simul_spikes.wav");
e.loadToFloatArray(action: { |array|
	~density = array;
});

~avgRates = [];
g = Buffer.read(server: s, path: "C:\\Users\\transTeam\\Desktop\\neurons-main\\neurons-main\\avg_rates.wav");
g.loadToFloatArray(action: { |array|
	~avgRates = array;
});
)