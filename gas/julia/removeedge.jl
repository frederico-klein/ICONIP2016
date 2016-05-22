function  removeedge(C, C_age) 
global amax
row, col = findnz(C_age .> amax);
a = size(row,2);
if !isempty(row)
    for i = 1:a
        C_age[row[i],col[i]] = 0;
        C_age[col[i],row[i]] = 0;
        C[row[i],col[i]] = 0;
        C[col[i],row[i]] = 0;
    end
end
return C, C_age
end
