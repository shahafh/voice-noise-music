function vnm_tempo_base_parser(files_list_txt_file)
	if nargin<1
		[dlg_name,dlg_path]=uigetfile({'*.txt','Text files (*.txt)'},'Выберите файл со списком базы');
		if dlg_name==0
			return;
		end
		files_list_txt_file=fullfile(dlg_path,dlg_name);
	end

	files_list=textread(files_list_txt_file,'%s','delimiter','\n','whitespace','');

	parfor i=1:length(files_list)
		cur_in=files_list{i};
		x=vb_readwav(cur_in);
		x=size(x);
		for ch=1:x(2)
			cur_out=sprintf('%s_ch%d.tempo',cur_in,ch);
			if not(exist(cur_out,'file'))
				vnm_tempo(cur_in, cur_out, num2str(ch));
			end
		end
	end
end
