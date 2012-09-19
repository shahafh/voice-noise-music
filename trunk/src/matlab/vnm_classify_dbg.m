function vnm_classify_dbg()
	alg=vnm_classify_cfg();

%	alg=rmfield(alg,'matlabpool');
%	alg.matlabpool={'local'};

%	vnm_classify('\\fileserver\Voicebases\Emotion\RnD Emotion\_Actors_STC\data\phrases','actors_st',alg);
%	vnm_classify('\\fileserver\Voicebases\Emotion\Berlin\data\','berlin',alg);

	vnm_classify('\\davydov-a\Bases\TelecomExpress','telecom',alg);
%	vnm_classify('\\davydov-a\Bases\Berlin\data','berlin',alg);

% 	alg=vnm_classify_cfg();

%	alg.obs_general.load_file.channel=2;
% 	vnm_classify('\\fileserver\Voicebases\Emotion\TelekomExpressMATLAB','folders',alg);
% 	delete('vnm_cache_folders_obs.mat');
% 	movefile('vnm_cache_folders_meta.mat', 'vnm_cache_folders_telecom-ch2_meta.mat');

%	alg=vnm_classify_cfg_fs();
%	alg=rmfield(alg,'matlabpool');

%	alg.classifier.proc.classes.folders.sex=struct('classes',[
%		struct(	'name','female',	'color','r',	'base_el',{{'d:\base\sex\female'}} );
%		struct(	'name','male',		'color','b',	'base_el',{{'d:\base\sex\male'}} ) ], ...
%		'obs_expr','x.pitch; x.lsf(:,11); x.mfcc(:,14)');

%	vnm_classify('\\Fileserver\Voicebases\Emotion\te_corpus_prepared','te_corpus',alg);

%	vnm_classify('e:\Corpora\Avec-DB\audio-train\train\','avecdb',alg);
 %	vnm_classify('d:\base\data','berlin', vnm_classify_cfg_fs);
%	vnm_classify('\\Fileserver\Voicebases\Emotion\Berlin\data\','berlin',alg);
%	vnm_classify('\\192.168.21.133\fileserver\Emotion\ST','st',alg);
%	vnm_classify('\\192.168.21.133\fileserver\Emotion\TelekomExpress','telecom',alg);

%{
%	delete('vnm_st_obs.mat');
%	delete('vnm_st_meta.mat');
%	alg.examine_obs.base_name='Sound 3';
%	vnm_classify('\\192.168.21.133\fileserver\Emotion\ST\2_states','st',alg);

%	delete('vnm_st_obs.mat');
%	delete('vnm_st_meta.mat');
%	alg.examine_obs.base_name='example_6_EMO';
%	vnm_classify('\\192.168.21.133\fileserver\Emotion\ST\2_states_01','st',alg);

	berlin_sub={'03a' '03b' '08a' '08b' '09a' '09b' '10a' '10b' '11a' '11b' '12a' '12b' '13a' '13b' '14a' '14b' '15a' '15b' '16a' '16b'};
	for i=1:length(berlin_sub)
		delete('vnm_berlin_obs.mat');
		delete('vnm_berlin_meta.mat');
		alg.examine_obs.base_name=berlin_sub{i};
		vnm_classify('\\192.168.21.133\fileserver\Emotion\Berlin\wav','berlin',alg);
	end

	vol=1;	num=5; %		Alarm! Alarm! Alarm!
	fs=16000; t=(0:fs-1)'/fs;
	sound(repmat(vol*chirp(t,100,1,5000),num,1),fs);
%}
end
