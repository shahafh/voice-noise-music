function [a,t]=vb_rotqr2ax(q)
%vb_rotqr2ax converts a real quaternion to the corresponding vb_rotation axis and angle
% Inputs: 
%
%     Q(4,1)   real-valued quaternion (with magnitude = 1)
%
% Outputs:
%
%     A(3,1)   Unit vector in the direction of the vb_rotation axis.
%     T        vb_rotation angle in radians (in range 0 to 2pi)
%
% In the quaternion representation of a vb_rotation, and q(1) = cos(t/2) 
% where t is the angle of vb_rotation in the range 0 to 2pi
% and q(2:4)/sin(t/2) is a unit vector lying along the axis of vb_rotation
% a positive vb_rotation about [0 0 1] takes the X axis towards the Y axis.
% 
%      Copyright (C) Mike Brookes 2007
%      Version: $Id: vb_rotqr2ax.m,v 1.2 2007/11/21 12:42:36 dmb Exp $
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
a=q(2:4);
m=sqrt(a'*a);
t=2*atan2(m,q(1));      % avoids problems if unnormalized
if m>0
    a=a/m;
else
    a=[0 0 1]';
end
    