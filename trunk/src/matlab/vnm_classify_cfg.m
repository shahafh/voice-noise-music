	function alg=vnm_classify_cfg()
%%	Raw observations configuration
	alg.obs_general=				struct(	'precision','single', ...
											'frame_size',0.030, 'frame_step',0.010, 'fs',8000, ...
											'snr', inf, ...
... %										'preemphasis',0.95, ...
... %										'filter',struct('band',[300 3400], 'order',10), ...
											'rand_ampl',10.^((-20:0.1:20)/20), ...
											'auto_load_cache',true, ...
											'load_file',struct('channel',1) ); % load_file.channel field can be 1(default),2,... or 'merge' or 'concatenate'
	alg.obs=       struct('type','time',	'params',struct(	'param_','value_') );
	alg.obs(end+1)=struct('type','power',	'params',struct(	'is_db',true, 'is_normalize',true) );

	gt3_cfg=[
		'<?xml version="1.0"?>' ...
		'<grundton3>' ...
			'<!--GrundTon 3.0.0.26 float SSE2 Intel-->' ...
			'<general frame_step="0.01" />' ...
			'<vad reestimation_time="5" min_db_range="20" db_range_part="0.5" min_pause="0.15" min_speech="0.2" />' ...
			'<tone f0_min="60" f0_max="500" f1_min="350" f1_max="2000" signal_band_min="100" signal_band_max="3400" voiced_min_length="0.04" unvoiced_min_length="0.02" />' ...
			'<dp LAG_WT="1" FREQ_WT="10000" DOUBL_C="0.35" dist_max2min="true" />' ...
			'<log enable="false" root="" />' ...
		'</grundton3>'];


	alg.obs(end+1)=struct('type','pitch',	'params',struct(	'normalize', true, ...
																'log',true, ... % Значения ЧОТ гораздо лучше описываются лог-нормальным или гамма-распределением, чем нормальным
																'grundton3_cfg',gt3_cfg) );
	
	alg.obs(end+1)=struct('type','tone',	'params',struct('f0_range',[80 500], 'f1_band',[350 2000], 'signal_band',[350 3400], 'median',0.070) );

	alg.obs(end+1)=struct('type','phonfunc','params',struct( 'window','hamming', 'delay',0.040) ); % phonetic function: log-spectral and Itakura–Saito LPC spectrum distances

	alg.obs(end+1)=struct('type','lsf',		'params',struct( 'window','hamming') );

	alg.obs(end+1)=struct('type','lpcc',	'params',struct( 'window','hamming') );
	
	alg.obs(end+1)=struct('type','rceps',	'params',struct( 'window','hamming', 'order',20) );

	alg.obs(end+1)=struct('type','mfcc',	'params',struct( 'window','hamming', 'bands_on_4kHz',23, 'norm_flt',true, 'sum_magnitude',false, 'order',13) );

	alg.obs(end+1)=struct('type','hos',		'params',struct( 'window','hamming') );

%	alg.obs(end+1)=struct('type','teo',		'params',struct( 'bands',[	  20	5300;	 150	 850;	 500	2500;	1500	3500;	2500	4500;
%																		  20     100;	 100	 200;	 200	 300;	 300	 400;	 400	 510;
%																		 510	 630;	 630	 770;	 770	 920;	 920	1080;	1080	1270;
%																		1270    1480;	1480	1720;	1720	2000;	2000	2320;	2320	2700;
%																		2700    3150;	3150	3700],	... %;	3700	4400;	4400	5300],	...
%											'band_norm',true,	'order',0.100) );

	alg.obs(end+1)=struct('type','specrel',	'params',struct('bands',[150 850; 500 2500; 1500 3500; 2500 4500]) );


	%% Meta observations configuration
	alg.meta_obs(end+1)=struct('type','vad',	'params',struct( 'tone',true,	'result_min_sz',0.150) );

%	alg.meta_obs(end+1)=struct('type','split',	'params',struct( 'size',2.5,	'step',0.8) ); % 'last',10.0

%	alg.meta_obs(end+1)=struct('type','intonogram','params',struct(	'obs',{{'power' 'pitch' 'lsf' 'lpcc' 'hos'}}, ... % 'teo'
%												'win_sz',0.300,		'speech_sz',1.0,	'pause_sz',0.100) );

%	obslist={'power'  'pitch'  'lsf'  'lpcc'  'rceps'  'mfcc'  'hos'  'specrel'}; % 'teo' 'rmmfcc'
	obslist={'pitch' 'lsf' 'lpcc' 'hos' 'phonfunc' 'specrel' 'mfcc' 'rceps'};
	d_obslist=strcat('d_',obslist);
%	d_d_obslist=strcat('d_',d_obslist);

	alg.meta_obs(end+1)=struct('type','delta',	'params',struct( 'obs',{obslist},	'delay',0.040) );
%	alg.meta_obs(end+1)=struct('type','delta',	'params',struct( 'obs',{d_obslist},	'delay',0.040) );

	alg.meta_obs(end+1)=struct('type','teo',	'params',struct( 'obs',{obslist},	'delay_half',0.040) );
%	alg.meta_obs(end+1)=struct('type','teo',	'params',struct( 'obs',{d_obslist},	'delay_half',0.040) );

%	alg.meta_obs(end+1)=struct('type','nomean',	'params',struct( 'obs',{obslist} ) ); % 'teo'

%	alg.meta_obs(end+1)=struct('type','nomedian','params',struct( 'obs',{obslist} ) ); % 'teo'
%	alg.meta_obs(end+1)=struct('type','nomedian','params',struct( 'obs',{d_obslist} ) ); % 'd_teo'
%	alg.meta_obs(end+1)=struct('type','nomedian','params',struct( 'obs',{d_d_obslist} ) ); % 'd_d_teo'

%	alg.meta_obs(end+1)=struct('type','sub_div_median','params',struct(	'obs',{obslist} ) ); % 'teo'
%	alg.meta_obs(end+1)=struct('type','sub_div_median','params',struct(	'obs',{d_obslist} ) ); % 'd_teo'
%	alg.meta_obs(end+1)=struct('type','sub_div_median','params',struct(	'obs',{d_d_obslist} ) ); % 'd_d_teo'

% 	alg.meta_obs(end+1)=struct('type','stat',	'params',struct(	'obs',{{'power'		'pitch'		'lsf'		'lpcc'		'mfcc'		'hos'		'teo'		'specrel'	...
%														'd_power'	'd_pitch'	'd_lsf'		'd_lpcc'	'd_mfcc'	'd_hos'		'd_teo'		'd_specrel'		...
%														'm_power'	'm_pitch'	'm_lsf'		'm_lpcc'	'd_d_mfcc'	'm_hos'		'm_teo'		'd_d_specrel'}},	...
%														'func',{{'y=std(x);  y(isnan(y)|isinf(y))=0;' 'y=skewness(x);  y(isnan(y)|isinf(y))=0;' 'y=kurtosis(x); y(isnan(y)|isinf(y))=0;' 'y=mean(x)-median(x);  y(isnan(y)|isinf(y))=0;'}} ) );

%	alg.meta_obs(end+1)=struct('type','select_obs','params',struct(	'pick',	{{'file_name'	'time'	'.*pitch' '.*lsf' '.*lpcc'}}));
%																	'del',	{{'power'	'.*d_pitch'}}));

	alg.meta_obs(end+1)=struct('type','isnan',	'params',struct( 'isremove',true, 'verbose',true) );


	svm_opt_arg={{'Kernel_Function','rbf', 'options',statset('MaxIter',1000000), 'kernelcachelimit',10000}};
    libsvm_opt_arg =' -c 512 -g 0.125 -rnd 10 -h 0 -q'; %  ' -c 8 -g 0.0078125 -h 0 -q'; %   ' -c 512 -g 0.0019531 -h 0 -q';


	%% Examine observations and feature selection
%	alg.examine_obs=struct(		'out_dir','.\examine_obs', ...
%								'make_cdf_pic',true, ...
%								'make_cdf_fig',false, ...
%								'skip_existed',true, ...
%								'base_auto_balance', true, ...
%								'objective_func', 'average_recall'); % 'accuracy' or 'average_recall'

	alg.feature_select=struct(	'svm_opt_arg', libsvm_opt_arg,...
								'log_root', '.\feature_select', ...
								'log_root_parfor', '.\parfor', ...
								'base_auto_balance', true, ...
								'objective_func', 'average_recall', ... % 'accuracy' or 'average_recall'
								'lrs_opt_arg', struct(	'modsel', true, ...
														'goal_set', 70, ...
														'L',	5, ...
														'R',	3),...
								'train_info', struct(	'K_fold',	20, ...
														'cv_steps',	1));


	%% Classification configuration
% 	cl_classes=vnm_classify_cfg_age();
%	cl_classes=vnm_classify_cfg_gender(cl_classes);
%	cl_classes=vnm_classify_cfg_berlin(cl_classes);
%	cl_classes=vnm_classify_cfg_actors_st(cl_classes);
% 	cl_classes=vnm_classify_cfg_savee(cl_classes);
% 	cl_classes=vnm_classify_cfg_enterface(cl_classes);
% 	cl_classes=vnm_classify_cfg_avecdb(cl_classes);
% 	cl_classes=vnm_classify_cfg_te_corpus(cl_classes);
%	cl_classes=vnm_classify_cfg_telecom(cl_classes);


	%% Classifiers configuration
%	alg.classifier.proc=	struct(	'K_fold',1, 'train_part',1, 'test_part',1, 'classes',cl_classes, 'save_path','./');
%	alg.classifier.proc=	struct('type',{{'K-fold' 'Random subsampling'}}, 'folds',20, 'train_part',0.7, 'classes',cl_classes, 'save_path','c:\EmoWork\'); % 'test_part',0.5

%	alg.classifier.gmm=struct(	'gmm_opt_arg',{{4, 'Replicates',3, 'Regularize',1e-6, 'options',statset('MaxIter',10000, 'TolX',1e-6)}});

%	alg.classifier.wks=struct(	'train_set_balance',false, 'svm_opt_arg',svm_opt_arg);

%	alg.classifier.wks_libsvm = struct(	'train_set_balance',false,  'libsvm_opt_arg', libsvm_opt_arg);

%	alg.classifier.hks_ova=struct('classifiers', [
%			struct('target','cl_anger',			'path','c:\EmoWork\vnm_berlin_wks_is_anger.mat',		'rate',0.90575);
%			struct('target','cl_sadness',		'path','c:\EmoWork\vnm_berlin_wks_is_sadness.mat',		'rate',0.88093);
%			struct('target','cl_boredom',		'path','c:\EmoWork\vnm_berlin_wks_is_boredom.mat',		'rate',0.85717);
%			struct('target','cl_neutral',		'path','c:\EmoWork\vnm_berlin_wks_is_neutral.mat',		'rate',0.85657);
%			struct('target','cl_happiness',		'path','c:\EmoWork\vnm_berlin_wks_is_happiness.mat',	'rate',0.82397);
%			struct('target','disgust_vs_fear',	'path','c:\EmoWork\vnm_berlin_wks_disgust_vs_fear.mat',	'rate',0.94565)]);
%{
	alg.classifier.hks_ova_ovo=struct('cl_ova', [
			struct('target','cl_boredom',		'path','c:\EmoWork\vnm_berlin_wks_is_boredom.mat',		'rate',0.85717);
			struct('target','cl_happiness',		'path','c:\EmoWork\vnm_berlin_wks_is_happiness.mat',		'rate',0.82397);
			struct('target','cl_disgust',		'path','c:\EmoWork\vnm_berlin_wks_is_disgust.mat',		'rate',0.81191);
			struct('target','cl_fear',			'path','c:\EmoWork\vnm_berlin_wks_is_fear.mat',			'rate',0.80934);
			struct('target','cl_neutral',		'path','c:\EmoWork\vnm_berlin_wks_is_neutral.mat',		'rate',0.85657);
			struct('target','cl_anger',			'path','c:\EmoWork\vnm_berlin_wks_is_anger.mat',			'rate',0.90575);
			struct('target','cl_sadness',		'path','c:\EmoWork\vnm_berlin_wks_is_sadness.mat',		'rate',0.88093)], ...
		'cl_ovo',[
			struct('target',{{'cl_neutral' 'cl_anger'}},	'path','c:\EmoWork\vnm_berlin_wks_neutral_vs_anger.mat',		'rate',0.99425);
			struct('target',{{'cl_neutral' 'cl_boredom'}},	'path','c:\EmoWork\vnm_berlin_wks_neutral_vs_boredom.mat',	'rate',0.89869);
			struct('target',{{'cl_neutral' 'cl_disgust'}},	'path','c:\EmoWork\vnm_berlin_wks_neutral_vs_disgust.mat',	'rate',0.93362);
			struct('target',{{'cl_neutral' 'cl_fear'}},		'path','c:\EmoWork\vnm_berlin_wks_neutral_vs_fear.mat',		'rate',0.95455);
			struct('target',{{'cl_neutral' 'cl_happiness'}},'path','c:\EmoWork\vnm_berlin_wks_neutral_vs_happiness.mat',	'rate',0.98837);
			struct('target',{{'cl_neutral' 'cl_sadness'}},	'path','c:\EmoWork\vnm_berlin_wks_neutral_vs_sadness.mat',	'rate',0.88441);
			struct('target',{{'cl_anger' 'cl_boredom'}},	'path','c:\EmoWork\vnm_berlin_wks_anger_vs_boredom.mat',		'rate',1);
			struct('target',{{'cl_anger' 'cl_disgust'}},	'path','c:\EmoWork\vnm_berlin_wks_anger_vs_disgust.mat',		'rate',0.93269);
			struct('target',{{'cl_anger' 'cl_fear'}},		'path','c:\EmoWork\vnm_berlin_wks_anger_vs_fear.mat',			'rate',0.91081);
			struct('target',{{'cl_anger' 'cl_happiness'}},	'path','c:\EmoWork\vnm_berlin_wks_anger_vs_happiness.mat',	'rate',0.8022);
			struct('target',{{'cl_anger' 'cl_sadness'}},	'path','c:\EmoWork\vnm_berlin_wks_anger_vs_sadness.mat',		'rate',0.99479);
			struct('target',{{'cl_boredom' 'cl_disgust'}},	'path','c:\EmoWork\vnm_berlin_wks_boredom_vs_disgust.mat',	'rate',0.93516);
			struct('target',{{'cl_boredom' 'cl_fear'}},		'path','c:\EmoWork\vnm_berlin_wks_boredom_vs_fear.mat',		'rate',1);
			struct('target',{{'cl_boredom' 'cl_happiness'}},'path','c:\EmoWork\vnm_berlin_wks_boredom_vs_happiness.mat',	'rate',0.98571);
			struct('target',{{'cl_boredom' 'cl_sadness'}},	'path','c:\EmoWork\vnm_berlin_wks_boredom_vs_sadness.mat',	'rate',0.90548);
			struct('target',{{'cl_disgust' 'cl_fear'}},		'path','c:\EmoWork\vnm_berlin_wks_disgust_vs_fear.mat',		'rate',0.94565);
			struct('target',{{'cl_disgust' 'cl_happiness'}},'path','c:\EmoWork\vnm_berlin_wks_disgust_vs_happiness.mat',	'rate',0.95833);
			struct('target',{{'cl_disgust' 'cl_sadness'}},	'path','c:\EmoWork\vnm_berlin_wks_disgust_vs_sadness.mat',	'rate',0.95262);
			struct('target',{{'cl_fear' 'cl_happiness'}},	'path','c:\EmoWork\vnm_berlin_wks_fear_vs_happiness.mat',		'rate',0.90114);
			struct('target',{{'cl_fear' 'cl_sadness'}},		'path','c:\EmoWork\vnm_berlin_wks_fear_vs_sadness.mat',		'rate',0.97071);
			struct('target',{{'cl_happiness' 'cl_sadness'}},'path','c:\EmoWork\vnm_berlin_wks_happiness_vs_sadness.mat',	'rate',0.98387)]);
%}
%	alg.matlabpool={'local'};
end
