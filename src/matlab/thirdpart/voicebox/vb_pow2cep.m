function [u,v]=vb_pow2cep(m,c,mode)
%vb_cep2pow convert cepstral means and variances to the power domain
% Inputs:
%    m: vector giving means in the power domain
%    c: covariance matrix in the power domain
% mode: 'c'  pow=exp(vb_irdct(cep))   [default]
%       'f'  pow=exp(vb_rsfft(cep)/n)  [fft length even]
%       'fo' pow=exp(vb_rsfft(cep)/n)  [fft length odd]
%       'i'  pow=exp(cep)           [ no transformation ]
%
% Outputs:
%    u: row vector giving the cepstral means with u(1) the 0'th cepstral coefficient
%    v: cepstral covariance matrix

%      Copyright (C) Mike Brookes 1998
%      Version: $Id: vb_pow2cep.m,v 1.4 2007/05/04 07:01:39 dmb Exp $
%
%   VOICEBOX is a MATLAB toolbox for speech processing.
%   Home page: http://www.ee.ic.ac.uk/hp/staff/dmb/voicebox/voicebox.html
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 2 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You can obtain a copy of the GNU General Public License from
%   http://www.gnu.org/copyleft/gpl.html or by writing to
%   Free Software Foundation, Inc.,675 Mass Ave, Cambridge, MA 02139, USA.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<3 mode='c'; end
if min(size(c))==1
   v=diag(c);
end
m=m(:)';        % force to be a row vector
q=log(1+c./(m'*m));
p=log(m)-0.5*diag(q)';
if any(mode=='f')
   n=2*length(m)-2;
   if any(mode=='o')
      n=n+1;
   end
   u=vb_rsfft(p,n);
   v=vb_rsfft(vb_rsfft(q,n)',n);
elseif any(mode=='i')
    u=p;
    v=q;
else
   u=vb_rdct(p);
   v=vb_rdct(vb_rdct(q)');
end
