function vnm_add_noise_to_signal(signal_file,noise_file, out_directory,SNR_dB)
	SNR=10^(SNR_dB/10);
	[x,fs]=wavread(signal_file);
	[n,fn]=wavread(noise_file);
	n=resample(n,fs,fn);
	nmin=min(length(x),length(n));
	n=n(1:nmin);
	x=x(1:nmin);
	SNR0=mean(x.*x)/mean(n.*n);
	a=sqrt(SNR/(SNR+1));
	b=sqrt(SNR0/(SNR+1));
	y=a*x+b*n;
	ym=max(abs(y));
	y=y/ym*0.9;
	nsf=ls(signal_file);
	nnf=ls(noise_file);
	new_nsf=strrep(nsf,'.wav',['_' num2str(SNR_dB) 'dB_' nnf(1) '.wav']);
	wavwrite(y,fs,[out_directory filesep new_nsf]);
end