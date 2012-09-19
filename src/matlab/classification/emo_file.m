function vnm_file(in_file, in_est_delay)
	if nargin<1
		[dlg_name,dlg_path]=uigetfile({'*.wav','Wave files (*.wav)'},'Select file for processing');
		if dlg_name==0
			return;
		end
		in_file=fullfile(dlg_path,dlg_name);
	end

	if nargin<2
		in_est_delay=inputdlg({'Statistical analysis interval (sec.)'},'Options',1,{'10'});
		if isempty(in_est_delay)
			return;
		end
		in_est_delay=str2double(in_est_delay{1});
	end

	[x,fs]=wavread(in_file);
	if size(x,2)>1
		[~,file_name]=fileparts(in_file);
		for ch=1:size(x,2)
			tmp_file=[tempdir() file_name '_ch' num2str(ch) '.wav'];
			cur_x=x(:,ch);
			wavwrite(cur_x, fs, 16, tmp_file);
			vnm_file(tmp_file, in_est_delay);
			delete(tmp_file);
		end
		return;
	end

	f0=estimate_f0(in_file);
	if not(isempty(f0.err))
		msgbox(f0.err, 'Error', 'error');
		return;
	end

	est.delay=round(in_est_delay/f0.dt);
	est.time=est.delay:round(est.delay*0.02):length(f0.freq);
	if isempty(est.time)
		msgbox('Too few vocal data. Recomended vocal length is 60 sec.', 'Error', 'error');
		return;
	end

	est.val=zeros(length(est.time),1);
	for i=1:length(est.time)
		cur_f0=f0.freq(est.time(i)-est.delay+1:est.time(i));
		cur_est=estimations(cur_f0);
		est.val(i,1:size(cur_est,1))=[cur_est{:,1}];
	end
	est_val4_stat=[mean(est.val(:,4)) std(est.val(:,4))];
	est.val(:,4)=(est.val(:,4)-est_val4_stat(1)) / est_val4_stat(2);
	est.time=f0.time(est.time-round(est.delay/2));

	est.names=estimations(rand(10,1));
	est.names(:,1)=[];

	tmp_txt=[tempname() '.txt'];
	tmp_wav=[tempname() '.wav'];
	wavwrite(x, fs, 16, tmp_wav);
	[dos_status, dos_result]=dos(['"' fileparts(which('f0_grundton')) filesep 'grundton_bandle' filesep 'vnm_cmd.exe" "' tmp_wav '" "' tmp_txt '"']);  %'" 1> nul 2>&1']);
	if dos_status~=0
		disp(['vnm_cmd call return ' num2str(dos_status)]);
		disp('Output:');
		disp(dos_result);
		error('pda:vnm_cmd', ['vnm_cmd call return ' num2str(dos_status)]);
	end
	[vnm_time, vnm_est]=textread(tmp_txt, '%n%n');
	delete(tmp_wav);
	delete(tmp_txt);
	vnm_name=regexp(dos_result, 'emo\(\w+\)', 'match');

	plot_estimations(in_file, f0, est, vnm_time, vnm_est, vnm_name{1}, est_val4_stat);
end

function f0=estimate_f0(file)
	f0.freq=[];
	f0.time=[];
	f0.raw=[];
	f0.err=[];
	f0.dt=0;
	
	gt_cfg.frame_step=		0.010;
	gt_cfg.frame_size=		0.040;
	gt_cfg.f0_range_min=	50;
	gt_cfg.f0_range_max=	800;

	gt_cfg.harm_freq=		3000;
	gt_cfg.harm_win=		true;
	gt_cfg.harm_lpc=		true;
	gt_cfg.harm_fs_mul=		1;

	gt_cfg.fine_do=			true;
	gt_cfg.fine_win=		true;
	gt_cfg.fine_lpc=		false;
	gt_cfg.fine_fs_mul=		1;
	gt_cfg.fine_part=		0.05;

	gt_cfg.dp_dt0_max=		0.05;
	gt_cfg.dp_look_up=		0.100;
	gt_cfg.dp_sum_factor=	1.07;

	gt_cfg.tone_vocal=		0.50;
	gt_cfg.tone_power=		-40;
	gt_cfg.tone_reg_vocal=	0.060;
	gt_cfg.tone_reg_unvocal=0.040;	

	[x,fs]=wavread(file);
	[f0.raw.freq, f0.raw.time, f0.raw.tone]=f0_grundton(x, fs, gt_cfg);

	f0.dt=f0.raw.time(2)-f0.raw.time(1);
	f0.freq=f0.raw.freq(f0.raw.tone>0.1);
	f0.time=f0.raw.time(f0.raw.tone>0.1);
	if isempty(f0.freq)
		f0.err='Can''t find vocal regions in this file.';
	end
end

function plot_estimations(file, f0, est, vnm_time, vnm_est, vnm_name, est_val4_stat)
	[x,fs]=wavread(file);
	x(:,2:end)=[];

	fig=figure('Name','Stress estimation', 'NumberTitle','off', 'Toolbar','figure', 'Units','pixels', ...
		'Position',get(0,'ScreenSize'), 'WindowButtonDownFcn', @OnMouseClick, 'CloseRequestFcn',@OnCloseRequest);

	sub_plot(1)=subplot(4,1,1,'Units','normalized');
	x_lim=[0 (size(x,1)-1)/fs];
	plot_sig_val=x(1:4:end);
	plot_sig_time=(0:length(plot_sig_val)-1)*4/fs;
	plot(plot_sig_time, plot_sig_val);
	xlabel('Time, sec');
	ylabel('Signal');
	y_lim=max(abs(x))*1.1*[-1 1];
	axis([x_lim y_lim]);
	grid on;
	stat_line(1)=line([0 0], y_lim, 'Color','m', 'LineWidth',1.5);
	stat_line(2)=line([0 0], y_lim, 'Color','k', 'LineWidth',1.5);
	stat_line(3)=line([0 0], y_lim, 'Color','m', 'LineWidth',1.5);
	caret(1)=line([0 0], y_lim, 'Color','r', 'LineWidth',2);

	subplot(4,1,2, 'Units','normalized');
	f0_raw_freq=f0.raw.freq;
	f0_raw_freq(f0.raw.tone<0.1)=0;
	plot(f0.raw.time, f0_raw_freq);
	y_lim=ylim();
	axis([x_lim y_lim]);
	grid on;
	xlabel('Time, sec');
	ylabel('Fundamental frequency, Hz');
	stat_line(4)=line([0 0], y_lim, 'Color','m', 'LineWidth',1.5);
	stat_line(5)=line([0 0], y_lim, 'Color','k', 'LineWidth',1.5);
	stat_line(6)=line([0 0], y_lim, 'Color','m', 'LineWidth',1.5);
	caret(2)=line([0 0], y_lim, 'Color','r', 'LineWidth',2);

	sub_plot(2)=subplot(4,1,[3 4], 'Units','normalized');
	est_line=zeros(size(est.val,2),1);
	for ei=1:size(est.val,2)
		est_line(ei)=plot(est.time, est.val(:,ei), est.names{ei,2});
		hold on;
	end
	est_line(end+1)=plot(vnm_time, vnm_est,'rx-');
	hold off;
	xlabel('Time, sec');
	ylabel('Estimations');
	est_ylim=ylim();
	axis([x_lim est_ylim]);
	grid on;
	legend({est.names{:,1},vnm_name});
	legend('boxoff');
	stat_line(7)=line([0 0], est_ylim, 'Color','m', 'LineWidth',1.5);
	stat_line(8)=line([0 0], est_ylim, 'Color','k', 'LineWidth',1.5);
	stat_line(9)=line([0 0], est_ylim, 'Color','m', 'LineWidth',1.5);
	caret(3)=line([0 0], est_ylim, 'Color','r', 'LineWidth',2);

	title(sprintf('File %s. Statistical analysis interval %.1f sec.',file, est.delay*f0.dt),'Interpreter','none');

	ctrl_pos=get(sub_plot(1),'Position');
	btn_play=uicontrol('Parent',fig, 'Style','pushbutton', 'String','Play view', 'Units','normalized', ...
		'Position',[ctrl_pos(1)+ctrl_pos(3)-0.075 ctrl_pos(2)+ctrl_pos(4) 0.075 0.03], 'Callback', @OnPlaySignal);

	ctrl_pos=get(sub_plot(2),'Position');
	ctrl_pos=[ctrl_pos(1)+ctrl_pos(3)+0.001 ctrl_pos(2)+ctrl_pos(4) 0 0.03];
	ctrl_pos(3)=1-ctrl_pos(1);
	for ei=1:size(est.val,2)
		ctrl_pos(1:2)=[ctrl_pos(1) ctrl_pos(2)-ctrl_pos(4)];
		uicontrol('Parent',fig, 'Style','checkbox', 'String',est.names{ei,1}, ...
			'Units','normalized', 'Position',ctrl_pos, 'Value',1, 'Callback', @OnSwitchView, 'UserData',est_line(ei));
	end
	ctrl_pos(1:2)=[ctrl_pos(1) ctrl_pos(2)-ctrl_pos(4)];
	uicontrol('Parent',fig, 'Style','checkbox', 'String',vnm_name, ...
		'Units','normalized', 'Position',ctrl_pos, 'Value',1, 'Callback', @OnSwitchView, 'UserData',est_line(end));

	set(zoom,'ActionPostCallback',@OnZoomPan);
	set(pan ,'ActionPostCallback',@OnZoomPan);
	zoom xon;
	set(pan, 'Motion', 'horizontal');

	player = audioplayer(x, fs);
	set(player, 'StartFcn',@CallbackPlay, 'StopFcn',@CallbackPlayStop, ...
				'TimerFcn',@CallbackPlay, 'UserData',struct('caret',caret, 'btn_play',btn_play), 'TimerPeriod',1/25);

	data = guihandles(fig);
	data.user_data = struct('player',player, 'btn_play',btn_play, ...
							'x_len',x_lim(2), 'sub_plot',sub_plot, ...
							'f0',f0, 'est',est, 'est_val4_stat',est_val4_stat, ...
							'stat_line',stat_line, 'fig_stat',-1);
	guidata(fig,data);
end

function est=estimations(x)
	fr=quantile(x, [0.25 0.5 0.75]);
	est={	((fr(3)-fr(2)) - (fr(2)-fr(1)))/std(x)		'Quantiles'				'b';
			skewness(x)									'Asymmetry'				'r';
			skewness_from_median(x)						'Asymmetry from median'	'g';
			-median(x)									'Norm Median'			'k';
			15*(1-median(x)/mean(x))					'15*(1-median/mean)'	'm';
			15*(1-median(x)/rms(x))						'15*(1-median/rms)'		'b--';
			-median(x)/std(x)+5							'-median/std+5'			'r--';
			(240-median(x))/40							'(240-median)/40'		'k--'};
end

function y=rms(x)
	y=sqrt(mean(x.*x));
end

function r=skewness_from_median(x) % asymmetry form median
	med_x = x-median(x);
	med_std = sqrt( sum(med_x.^2) / max(1,length(med_x)-1) );
	r = mean(med_x.^3) / (med_std^3);
end

function OnSwitchView(hObject, eventdata)
	if get(hObject,'Value')
		line_view='on';
	else
		line_view='off';
	end
	set(get(hObject,'UserData'), 'Visible', line_view);
end

function OnPlaySignal(hObject, eventdata)
	data = guidata(hObject);
	if not(isplaying(data.user_data.player))
		x_lim=min(data.user_data.player.TotalSamples, max(1, round( xlim()*data.user_data.player.SampleRate+1 ) ) );
		play(data.user_data.player, x_lim);
		set(data.user_data.btn_play, 'String', 'Stop playing');
	else
		stop(data.user_data.player);
	end
end

function CallbackPlay(obj, event, string_arg)
	user_data=get(obj, 'UserData');
	cur_pos=(get(obj, 'CurrentSample')-1)/get(obj, 'SampleRate');
	for i=1:length(user_data.caret)
		set(user_data.caret(i),'XData',[cur_pos cur_pos]);
	end
end

function CallbackPlayStop(obj, event, string_arg)
	CallbackPlay(obj);
	user_data=get(obj, 'UserData');
	set(user_data.btn_play, 'String', 'Play view');
end

function OnZoomPan(hObject, eventdata)
	data = guidata(hObject);

	x_lim=xlim();
	rg=x_lim(2)-x_lim(1);
	if x_lim(1)<0
		x_lim=[0 rg];
	end
	if x_lim(2)>data.user_data.x_len
		x_lim=[max(0, data.user_data.x_len-rg) data.user_data.x_len];
	end

	child=get(hObject,'Children');
	set( child( strcmp(get(child,'type'),'axes') & not(strcmp(get(child,'tag'),'legend')) ), 'XLim', x_lim);
end

function OnMouseClick(hObject, eventdata)
	axes_obj = get(hObject, 'CurrentAxes');
	axes_pos = get(axes_obj, 'Position');
	axes_lim = get(axes_obj, 'XLim');
	windw_pos = get(hObject, 'Position');
	mouse_pos = get(hObject, 'CurrentPoint');

	mouse_pos = [mouse_pos(1)/windw_pos(3) mouse_pos(2)/windw_pos(4)];
	mouse_pos = [(mouse_pos(1)-axes_pos(1))/axes_pos(3) (mouse_pos(2)-axes_pos(2))/axes_pos(4)];
	mouse_pos_x=mouse_pos(1)*(axes_lim(2)-axes_lim(1))+axes_lim(1);

	data = guidata(hObject);
	stat_line=data.user_data.stat_line;
	f0= data.user_data.f0;
	est=data.user_data.est;
	est_val4_stat=data.user_data.est_val4_stat;
	est_delay_2=round(est.delay/2);

	[~,mi]=min(abs(f0.time-mouse_pos_x));
	mi=min(length(f0.time)-est_delay_2, max(est_delay_2+1, mi));

	f0_ind=[mi-est_delay_2 mi mi+est_delay_2];

	for i=1:length(stat_line)
		set(stat_line(i), 'XData', f0.time(f0_ind( rem([i i]-1,length(f0_ind))+1 )));
	end
	
	try
		findobj(data.user_data.fig_stat);
	catch
		data.user_data.fig_stat=figure('Name','F0 statistics');
		guidata(hObject,data);
	end

	figure(data.user_data.fig_stat);
	cur_f0=f0.freq(f0_ind(1):f0_ind(end));
	[hy,hx]=hist(cur_f0,40);
	bar(hx, hy/length(cur_f0));
	grid on;
	xlabel('Fundamental frequency, Hz');
	ylabel('Probability density');
	cur_est=estimations(cur_f0);
	cur_est{4,1}=(cur_est{4,1}-est_val4_stat(1)) / est_val4_stat(2);
	titl=[];
	for ei=1:size(cur_est,1)
		titl=[titl sprintf('%s %f,', cur_est{ei,2}, cur_est{ei,1})];
	end
	title(titl, 'Interpreter','none');
end

function OnCloseRequest(hObject, eventdata)
	try
		data = guidata(hObject);
		delete(data.user_data.fig_stat);
	catch
	end
	delete(hObject);
end
