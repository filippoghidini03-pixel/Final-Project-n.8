function [g] = filter_prices(prices)
treshold = 0.5 ;
g=prices;

for i = 2:length(prices)-1
    if(abs(prices(i)-prices(i-1))>treshold && abs(prices(i+1)-prices(i))>treshold && (prices(i)-prices(i-1))*(prices(i+1)-prices(i))<0 )
    g(i)=(prices(i+1)+prices(i-1))/2 ;
    else
        g(i) = prices(i);
    end
end

end