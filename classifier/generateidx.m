function [polidx, velidx] = generateidx(varargin)
lllen = varargin{1};
if nargin==1        
    switch lllen 
        case 75
            %%%%regular skeleton
            polidx = [1:75];
            velidx = [];
        case 150
            %%%%skeleton + velocities
            polidx = [1:25 51:75 101:125];
            velidx = [26:50 76:100 126:150];
        case 72
            %%%%skeleton - hips
            polidx = [1:72];
            velidx = [];
        case 147
            %%%%skeleton - hips + velocities
            polidx = [1:24 50:73 99:122];
            velidx = [25:49 74:98 123:147];
        case 90
            %%%%simple skeleton+ velocities from CAD60
            polidx = [1:15 31:45 61:75];
            velidx = [16:30 46:60 76:90];
        otherwise
            error('Strange size')
            %%%%regular skeleton
    end
else
    skelldef = varargin{2};
    pick = skelldef.length;
    [polidx, velidx] = generateidx(pick);
    polidx = setdiff(polidx,skelldef.realkilldim);
    velidx = setdiff(velidx,skelldef.realkilldim);  
    polflag = 1*ones(1,size(polidx,2)); polidxf = [polidx; polflag]; 
    velflag = 0*ones(1,size(velidx,2)); velidxf = [velidx; velflag];     
    wholeskel = [polidxf velidxf];
    [~, II] = sort(wholeskel(1,:)); 
    sortedskel = wholeskel(:,II);
    sortedskel(1,:) = 1:size(wholeskel,2); 
    polidx = sortedskel(:,sortedskel(2,:)==1);
    velidx = sortedskel(:,sortedskel(2,:)==0);
    polidx = polidx(1,:);
    velidx = velidx(1,:);    
end