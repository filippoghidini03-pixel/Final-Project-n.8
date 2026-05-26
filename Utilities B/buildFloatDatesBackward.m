function floatDates = buildFloatDatesBackward(T, t0)
%BUILDFLOATDATESBACKWARD  Build quarterly ASW floating-leg dates BACKWARD from T.
%
%   Starting from T, steps back by 3 calendar months at a time, applying
%   Modified Following via shiftDate.m (same function used in bootstrapEONIA).
%   Stops when the next backward step would reach or pass t0.
%
%   Returns chronological vector: [t0, d_{K-1}, ..., d_1, T]
%   The first period [t0, d_{K-1}] is in general a SHORT STUB.
%
%   This "backward" construction anchors the regular quarterly periods at T,
%   as required by Baviera-Lebovitz (2015): the discount factors and yearfracs
%   in the denominator are therefore taken on a grid ending exactly at expiry.

dates = T;
d = T;
while true
    d_prev = shiftDate(d, -3, 'months');   % 3 months back + Mod-Following
    if d_prev <= t0
        break
    end
    dates = [d_prev; dates];  %#ok<AGROW>
    d = d_prev;
end

floatDates = [t0; dates];   % t0 is the start of the short stub
end
