function [vnm_est, vnm_time, vnm_name]=vnm_dll_call(file_name_or_x, fs, stat_sz)
	if nargin<1
		[dlg_name,dlg_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Выберите файл для обработки');
		if dlg_name==0
			return;
		end
		file_name_or_x=fullfile(dlg_path,dlg_name);
	end

	if isa(file_name_or_x,'char')
		[file_name_or_x,fs]=vb_readwav(file_name_or_x);
	end
	file_name_or_x(:,2:end)=[];
	
	tmp_wav=[tempname() '.wav'];
	wavwrite(file_name_or_x, fs, 16, tmp_wav);

	tmp_txt=[tempname() '.txt'];
	
	if nargin>=3
		stat_sz=[' ' num2str(stat_sz)];
	else
		stat_sz='';
	end

	[dos_status, dos_result]=dos(['"' fileparts(which('f0_grundton')) filesep 'grundton_bandle' filesep 'vnm_cmd.exe" "' tmp_wav '" "' tmp_txt '"' stat_sz]);  %'" 1> nul 2>&1']);
	if dos_status~=0
		disp(['vnm_cmd call return ' num2str(dos_status)]);
		disp('Output:');
		disp(dos_result);
		error('emo:vnm_cmd', ['vnm_cmd call return ' num2str(dos_status)]);
	end
	[vnm_time, vnm_est]=textread(tmp_txt, '%n%n');
	vnm_est=vnm_est*25;
	if not(isa(file_name_or_x,'char'))
		delete(tmp_wav);
	end
	delete(tmp_txt);

	vnm_name=regexp(dos_result, 'emo\(\w+\)','match');
	vnm_name=vnm_name{1};

	if nargout<1
		figure('Units','pixels', 'Position',get(0,'ScreenSize'));
		subplot(3,1,1);
		if isa(file_name_or_x,'char')
			file_name=file_name_or_x;
			[file_name_or_x,fs]=vb_readwav(file_name_or_x);
		else
			file_name='signal';
		end
		plot((0:size(file_name_or_x,1)-1)/fs, file_name_or_x);
		x_lim=[0 (size(file_name_or_x,1)-1)/fs];
		axis([x_lim max(abs(file_name_or_x))*1.1*[-1 1] ]);
		grid on;

		subplot(3,1,2);
		plot(vnm_time, vnm_est);
		axis([x_lim ylim()]);
		grid on;
		
		subplot(3,1,3);
		[ef,ex]=ecdf(vnm_est);
		plot(ex,ef);
		grid on;

		set(zoom,'ActionPostCallback',@OnZoomPan);
		set(pan ,'ActionPostCallback',@OnZoomPan);
		zoom xon;
		set(pan, 'Motion', 'horizontal');
		
		title(vnm_name, 'Interpreter','none');

		clear('vnm_time','vnm_est');
	end
end

function OnZoomPan(hObject, eventdata)
	x_lim=xlim();
	subplot(3,1,1);	xlim(x_lim);
	subplot(3,1,2);	xlim(x_lim);
% 	child=get(hObject,'Children');
% 	set( child( strcmp(get(child,'type'),'axes') & not(strcmp(get(child,'tag'),'legend')) ), 'XLim', xlim());
end
