function [ar,e,dc]=vb_lpccovar(s,p,t,w)
%vb_lpccovar performs covariance LPC analysis [AR,E,DC]=(S,P,T)
%
%  Inputs:  S(NS)    is the input signal
%           P        is the order (default: 12)
%           T(NF,:)  specifies the frames size details: each row specifies one frame
%                    T can be a cell array if rows have unequal numbers of values
%                       T(:,1) gives the start of the analysis interval: must be >P
%                       T(:,2) gives the end of the anaylsis interval [default: t(:+1,1)-1]
%                       subsequent pairs can be used to specify multiple disjoint segments
%                    If T is omitted, T(1,1)=P+1, T(1,2)=NS;
%                    The elements of t need not be integers.
%           W(NS)    The error at each sample is weighted by W^2 (default: 1)
%
% Outputs:  AR(NF,P+1)  are the AR coefficients with AR(:,1) = 1
%           E(NF,2)     is the energy in the residual and in the original window.
%                       sqrt(E) is often called the 'gain' of the LPC filter.
%           DC          is the DC component of the signal S. If this output is included,
%                       the LPC equations are modified to include a DC offset.

% Notes:
%
% (1) For speech processing P should be at least 2*F*L/C where F is the sampling
%     frequency, L the vocal tract length and C the speed of sound. For a typical
%     male (l=17 cm) this gives f/1000.
%
% (2) Each analysis frame should contain at least 2P samples. If note (1) is followed
%     this implies at least 2 ms of speech signal per frame.
%
% (3) It can be advantageous to restrict the analysis regions to time intervals
%     when the glottis is closed (closed-phase analysis). This can be achieved by
%     setting the T input parameter appropriately. If the closed-phase is shorter than
%     2 ms then two or more successive closed-phases should be used by defining 4 or more
%     elements in the corresponding row of T.
%
% (4) A previous version of this routine allowed T() to have a single row which would
%     be replicated for the entire file length. This has be removed because it gave rise
%     to an ambiguity.

%  Bugs: sould really detect a singular matrix and reduce the order accordingly

%	   Copyright (C) Mike Brookes 1995
%      Version: $Id: vb_lpccovar.m,v 1.4 2007/05/04 07:01:38 dmb Exp $
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

s = s(:); % make it a column vector
if nargin < 2 p=12; end;
if nargin < 3 t=[p+1 length(s)]; end;
wq = nargin>3;
[nf,ng]=size(t);
if iscell(t)
   t{nf+1}=length(s)+1;
else
   if rem(ng,2)
      t(:,end+1)=[t(2:nf,1)-1; length(s)];
   end
end
ar=zeros(nf,p+1);
ar(:,1)=1;
e=zeros(nf,2);
dc=zeros(nf,1);
d0=nargout >2;

rs=(1:p);

for jf=1:nf
   if iscell(t)
      tj=t{jf};
      if rem(length(tj),2)
         tj(end+1)=t{jf+1}(1)-1;
      end
   else
      tj=t(jf,:);
   end
   
   ta = ceil(tj(1));
   tb = floor(tj(2));
   cs = (ta:tb).';
   for js=3:2:length(tj)
      ta = ceil(tj(js));
      tb = floor(tj(js+1));
      cs = [cs; (ta:tb).'];
   end
   %disp(cs([logical(1); (cs(2:end-1)~=cs(1:end-2)+1)|(cs(2:end-1)~=cs(3:end)-1); logical(1)])');
   nc = length(cs);
   pp=min(p,nc-d0);
   dm=zeros(nc,pp);	% predefine shape
   dm(:) = s(cs(:,ones(1,pp))-rs(ones(nc,1),1:pp));
   if nargout>2
      if wq
         dm = [ones(nc,1) dm].*w(cs(:,ones(1,1+pp)));
         sc=(s(cs).*w(cs));
         aa = (dm\sc).';
      else
         dm = [ones(nc,1) dm];
         sc=s(cs);
         aa = (dm\sc).';
      end
      ar(jf,2:pp+1) = -aa(2:pp+1);
      e(jf,1)=sc.'*(sc - dm*aa.');
      e(jf,2)=sc.'*sc;
      dc(jf)=aa(1)/sum(ar(jf,:));
   else
      if wq
         dm = dm.*w(cs(:,ones(1,pp)));
         sc=(s(cs).*w(cs));
         aa = (dm\sc).';
      else
         sc=s(cs);
         aa = (dm\sc).';
      end;
      ar(jf,2:pp+1) = -aa;
      if nargout>1
         e(jf,1)=sc.'*(sc - dm*aa.');
         e(jf,2)=sc.'*sc;
      end
   end
end
if ~nargout
   vb_lpcar2db(ar,127);
end

