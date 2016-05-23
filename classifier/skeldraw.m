function A = skeldraw(varargin)
if length(varargin)==1
    doIdraw = true;
    skel = varargin{1};
elseif length(varargin)==2
    skel = varargin{1};
    doIdraw = varargin{2};
else
    error('too many input arguments')    
end
A = [];
cellA = [];
markers = false;
if size(skel,3)==1 
    if size(skel,2) ~=1
        for i = 1:(size(skel,2)-1)
            tdskel = cat(3, makefatskel(skel(:,i)),makefatskel(skel(:,i+1)));
            [AA,cellAA] = constructA(remove_excess(tdskel));
            cellA = cat(2, cellA, {cellAA}); 
            A = cat(2, A, AA);
        end
    else
        tdskel = cat(3,makefatskel(skel),makefatskel(skel));
        [A,cellA] = constructA(remove_excess(tdskel));
    end
else
    for i =1:(size(skel,3)-1)
        tdskel = cat(3,skel(:,:,i),skel(:,:,i+1));
        [AA,cellAA] = constructA(remove_excess(tdskel));
        cellA = cat(2, cellA, {cellAA}); 
        A = cat(2, A, AA);        
    end
end
if doIdraw
    hold_initialstate = ishold();
    hold on
    if markers
        for ll = 1:2            
            plot3(tdskel(:,1,ll), tdskel(:,2,ll), tdskel(:,3,ll),'.y','markersize',15); view(0,0); axis equal;            
            for k=1:25 
                text(tdskel(k,1,ll), tdskel(k,2,ll), tdskel(k,3,ll),num2str(k))
            end
        end
    end    
    mycmap = colormap( gca ,winter(size(cellA,2)));
    try
        pp = plot3(cellA{:});        
    catch
        plotA = [cellA{:}];
        pp = plot3(plotA{:});
    end
    for i = 1: size(cellA,2)
        pp(i).Color = mycmap(i,:);
    end        
    hold off
    if hold_initialstate == 1
        hold on
    end    
end
end
function tdskel = remove_excess(tdskel)
if size(tdskel,1) > 25
    wheretoclip = mod(size(tdskel,1),25);
    if wheretoclip==0
        wheretoclip = 25;
    end
    tdskel = tdskel(1:wheretoclip,:,:);
end
if size(tdskel,1) == 24
    tdskel = [[0 0 0 ];tdskel]; 
elseif size(tdskel,1) < 24
    error('strange size ')
end
end
function [A, cellA] = constructA(tdskel)
moresticks = [];
for i=1:size(tdskel,1)
    moresticks = cat(2,moresticks,[tdskel(i,:,1);tdskel(i,:,2); [NaN NaN NaN]]');
end
A1 = stick_draw(tdskel(:,:,1));
A2 = stick_draw(tdskel(:,:,2));
A = [A1 A2 moresticks];
cellA = {A(1,:),A(2,:), A(3,:)};
end
function a = stick_draw(tdskel)
a = draw_1_stick(tdskel, 1,2);
a= [a draw_1_stick(tdskel, 2,21)];
a= [a draw_1_stick(tdskel, 21,3)];
a= [a draw_1_stick(tdskel, 3,4)];
a= [a draw_1_stick(tdskel, 5,21)];
a= [a draw_1_stick(tdskel, 21,9)];
a= [a draw_1_stick(tdskel, 5,6)];
a= [a draw_1_stick(tdskel, 6,7)];
a= [a draw_1_stick(tdskel, 7,8)]; % unsure
a= [a draw_1_stick(tdskel, 8,22)];
a= [a draw_1_stick(tdskel, 22,23)]; % unsure
a= [a draw_1_stick(tdskel, 8,23)]; % unsure
a= [a draw_1_stick(tdskel, 9,10)];
a= [a draw_1_stick(tdskel, 10,11)];
a= [a draw_1_stick(tdskel, 11,12)]; % unsure
a= [a draw_1_stick(tdskel, 12,24)];
a= [a draw_1_stick(tdskel, 12,25)]; % unsure
a= [a draw_1_stick(tdskel, 24,25)];
a= [a draw_1_stick(tdskel, 13,1)];
a= [a draw_1_stick(tdskel, 1,17)];
a= [a draw_1_stick(tdskel, 13,17)]; % ?
a= [a draw_1_stick(tdskel, 13,14)];
a= [a draw_1_stick(tdskel, 14,15)];
a= [a draw_1_stick(tdskel, 15,16)];
a= [a draw_1_stick(tdskel, 17,18)];
a= [a draw_1_stick(tdskel, 18,19)];
a= [a draw_1_stick(tdskel, 19,20)];
end
function A = draw_1_stick(tdskel, i,j)
A = [[tdskel(i,1) tdskel(j,1) NaN]; [tdskel(i,2) tdskel(j,2) NaN]; [tdskel(i,3) tdskel(j,3) NaN]];
end
