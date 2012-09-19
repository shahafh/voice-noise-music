function [base alg]=vnm_parse_berlin(db_path, alg)
	speaker_name_mask='\d\d\w';
	if isfield(alg,'examine_obs') && isfield(alg.examine_obs,'speaker_name')
		speaker_name_mask=alg.examine_obs.speaker_name;
	end

	base=[	struct('class','anger',		'data',{berlin_parse_dir(db_path, [speaker_name_mask '\d\dA\w\.wav'], alg)},  'color','r'); ...
			struct('class','boredom',	'data',{berlin_parse_dir(db_path, [speaker_name_mask '\d\dB\w\.wav'], alg)},  'color','b'); ...
			struct('class','disgust',	'data',{berlin_parse_dir(db_path, [speaker_name_mask '\d\dD\w\.wav'], alg)},  'color','g'); ...
			struct('class','fear',		'data',{berlin_parse_dir(db_path, [speaker_name_mask '\d\dF\w\.wav'], alg)},  'color','c'); ...
			struct('class','happiness',	'data',{berlin_parse_dir(db_path, [speaker_name_mask '\d\dH\w\.wav'], alg)},  'color','m'); ...
			struct('class','neutral',	'data',{berlin_parse_dir(db_path, [speaker_name_mask '\d\dN\w\.wav'], alg)},  'color','y'); ...
			struct('class','sadness',	'data',{berlin_parse_dir(db_path, [speaker_name_mask '\d\dS\w\.wav'], alg)},  'color','k')];

	%% Berlin multiclass
	alg.classifier.obs_expr={'x.phonfunc(:,4)' 'x.i_lsf(:,2)' 'x.st1_lsf(:,3)' 'x.st1_power(:,1)' 'x.lsf(:,1)' 'x.i_lsf(:,1)' ...
		'x.md_lsf(:,1)' 'x.i_lsf(:,2)' 'x.st1_d_mfcc(:,15)' 'x.sdm_teo(:,17)' 'x.t_d_mfcc(:,17)' 'x.lpcc(:,5)' ...
		'x.t_specrel(:,6)' 'x.j_pitch(:,1)' 'x.t_mfcc(:,11)' 'x.t_d_mfcc(:,9)' 'x.sdm_teo(:,8)' 'x.mfcc(:,7)' ...
		'x.st1_d_d_mfcc(:,6)' 'x.phonfunc(:,6)' 'x.lsf(:,13)' 'x.st1_d_lpcc(:,3)' 'x.st1_d_mfcc(:,1)' 'x.st1_d_mfcc(:,19)' ...
		'x.md_lsf(:,2)' 'x.st3_lsf(:,12)' 'x.mfcc(:,15)' 'x.i_hos(:,2)' 'x.i_lsf(:,3)' 'x.st1_d_d_mfcc(:,17)' ...
		'x.st1_d_d_mfcc(:,10)' 'x.pitch(:,1)' 'x.tone(:,1)' 'x.st1_mfcc(:,6)' 'x.t_d_pitch(:,1)' 'x.st3_d_mfcc(:,1)'};
end

function flist=berlin_parse_dir(db_path, mask, alg)
	db_list=dir(db_path);
	db_list([db_list.isdir])=[];

	db_list={db_list.name};
	db_mask=regexp(db_list, mask);
	db_list(cellfun(@isempty, db_mask))=[];

	male_list={'03' '10' '11' '12' '15'};
	female_list={'08' '09' '13' '14' '16'};

	flist=cell(length(db_list),1);
	for i=1:length(db_list)
		cur_speaker=db_list{i}([1 2]);
		if any(strcmp(cur_speaker,male_list))
			cur_gender='male';
		elseif any(strcmp(cur_speaker,female_list))
			cur_gender='female';
		else
			error('emo:parse:berlin','Can''t determine speaker gender for record %s.',db_list{i});
		end
		flist{i}=struct('file_name',[db_path filesep db_list{i}], 'speaker',cur_speaker, 'gender',cur_gender);
	end

	flist=vnm_parse_files(flist, alg);
end
