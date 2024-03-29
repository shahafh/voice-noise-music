function x=vb_choosrnk(n,k)
%vb_choosrnk All choices of K elements taken from 1:N with replacement. [X]=(N,K)
% The output X is a matrix of size ((N+K-1)!/(K!*(N-1)!),K) where each row
% contains a choice of K elements taken from 1:N with duplications allowed.
% The rows of X are in lexically sorted order.
%
% To choose from the elements of an arbitrary vector V use
% V(vb_choosrnk(LENGTH(V),K)).

%   Copyright (c) 1998 Mike Brookes,  mike.brookes@ic.ac.uk
%      Version: $Id: vb_choosrnk.m,v 1.3 2007/05/04 07:01:38 dmb Exp $
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
x=vb_choosenk(n+k-1,k);
x=x-repmat(0:k-1,size(x,1),1);