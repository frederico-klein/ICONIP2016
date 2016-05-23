function [tdskel,hh] = makefatskel(skel)
howmanyskels = size(skel,2);
if howmanyskels>1
    [tdskel,hh] = makefatskel(skel(:,1));
    for i = 2:howmanyskels
        [currskel, ~] = makefatskel(skel(:,i));
        tdskel = cat(3, tdskel, currskel );
    end
else    
    hh = size(skel,1)/3;
    if all(size(skel) == [75 1]) 
        tdskel = zeros(25,3);
        for i=1:3
            for j=1:25
                tdskel(j,i) = skel(j+25*(i-1));
            end
        end
    elseif all(size(skel) == [150 1])
        tdskel = reshape(skel,hh,3); 
    elseif all(size(skel) == [25 3])
        tdskel = skel;
    else
        try
            tdskel = reshape(skel,hh,3);
        catch
            disp('reshape failed.')
        end
    end
end
end
