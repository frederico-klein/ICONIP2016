function findneighbours(s,C)
row, col = findnz(C); # there will likely be infinite mistakes in indexing here...
neighbours = [];
for i = 1:length(row)
    if row[i] == s
        neighbours = vcat(neighbours, col[i]);
        #%C_age = spdi_add(C_age,s,col(i)); %omg, the horror.... but s = row(i) already is this it? I have no idea...
        #%cummax(cummax(C_age))
    end
end
#println("neighbours:")
##println(neighbours)
return neighbours
end
