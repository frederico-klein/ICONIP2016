function findnearest(p, data)
    maxindex = size(data,2);
    distvector = zeros(maxindex,1);
    for i = 1:maxindex
        distvector[i] = norm(data[:,i]- p);
    end
#println(size(vec(distvector)))
    index = sortperm(vec(distvector));
    ni1 = index[1];
    ni2 = index[2];
    n1 = data[:,ni1];
    n2 = data[:,ni2];
   return n1, n2, ni1, ni2, distvector
end
