function x=vb_usasi(n,fs)
%vb_usasi generates N samples of vb_usasi noise at sample frequency FS X=(N,FS)

% This routine is based on the vb_usasi noise defined in [1] which was later
% reissued as [2]. vb_usasi noise is intended to simulate the long-term average
% of typical audio program material. The routine does not currently implement
% the pulsation at 2.5Hz 12.5% duty cycle that is recommended by the standard.
% Also it should probably be scaled to a well-defined power.
%
%  [1] NRSC AM Reemphasis, Deemphasize, and Broadcast Audio Transmission Bandwidth Specifications,
%      EIA-549 Standard, Electronics Industries Association , July 1988.
%  [2] NRSC AM Reemphasis, Deemphasize, and Broadcast Audio Transmission Bandwidth Specifications,
%      NRSC-1-A Standard, Sept 2007, Online: http://www.nrscstandards.org/SG/NRSC-1-A.pdf 

%      Copyright (C) Mike Brookes 1997
%      Version: $Id: vb_usasi.m,v 1.6 2008/05/27 08:38:05 dmb Exp $
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

if nargin<2 fs=8000; end
b=[1 0 -1];
a=poly(exp(-[100 320]*2*pi/fs));

x=vb_randfilt(b,a,n);