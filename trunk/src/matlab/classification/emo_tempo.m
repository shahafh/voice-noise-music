function vnm_tempo(file_name_in, file_name_out, channel_number, phones_median, file_name_cfg)
	disp('vnm_tempo 1.0.0.5');

	if nargin<1
		disp('Usage: vnm_tempo <input_wav_file> <output_txt_file> [channel_number=1] [phones_median=3.5] [config_xml_file]');
		return;
	end

	%% Prepare signal
	[x,fs]=vb_readwav(file_name_in);
	if nargin<3
		channel_number=1;
	else
		channel_number=round(str2double(channel_number));
	end
	if channel_number<1 || channel_number>size(x,2)
		fprintf('Incorrect channel requested: %d from %d.\n', channel_number, size(x,2));
		return;
	end
	x=x(:,channel_number);

	%% Configure algorithm
	if nargin<5
		alg.obs.general=	struct(	'frame_size',0.020, 'frame_step',0.005, 'fs',fs);
		alg.obs.power=		struct(	'is_db',true, 'is_normalize',true);
		alg.meta.vad=		struct(	'power_quantile',0.25, 'power_threshold',-20, 'min_pause',0.300, 'min_speech',0.300);

		alg.obs.tone=		struct(	'window','rectwin', 'do_lpc',false, 'f0_range',[80 800], ...
									'power_quantile',0.25, 'median',0.040, 'threshold',0.7, 'min_reg_sz',0.040);
		alg.meta_obs.delta=	struct( 'obs',{{'tone'}},	'delay',0.020);

		alg.obs.pirogov=	struct(	'avr',0.020,	'diff',0.040,	'max_threshold',0.7,	'max_neighborhood',0.060,	'reg_sz',[0.045 0.250]);

		alg.obs.tempo=		struct(	'd_tone_thresholds',[-0.3 0.3], 'min_reg_sz',0.050,		'phones_median',3);
	else
		alg=xml_read(file_name_cfg);
	end

	if nargin<4
		alg.obs.tempo.phones_median=3.5;
	else
		alg.obs.tempo.phones_median=str2double(phones_median);
	end

	fprintf('Input file:%s\nOutput file:%s\nChannel number:%d\nPhones median size:%f\n', file_name_in, file_name_out, channel_number, alg.obs.tempo.phones_median);

	[~, tempo_t, tempo_val]=vnm_obs_tempo(x, alg, struct('file_name','signal', 'alg',alg));

	%% Save results
	out_fh=fopen(file_name_out,'w');
	if out_fh==-1
		disp(['Can''t create output file: ' file_name_out]);
	else
		fprintf(out_fh, '%d\t%f\n', [round(tempo_t(:)*fs) tempo_val(:)]');
		fclose(out_fh);
	end
end
