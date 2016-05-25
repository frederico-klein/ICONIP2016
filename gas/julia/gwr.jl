function gwr(data,MAXNUMBEROFNODES)

#the initial parameters for the algorithm:
global maxnodes, at, en, eb, h0, ab, an, tb, tn, amax, A, C

maxnodes = MAXNUMBEROFNODES; #maximum number of nodes/neurons in the gas
at = 0.95; #activity threshold
en = 0.006; #epsilon subscript n
eb = 0.2; #epsilon subscript b
h0 = 1;
ab = 0.95;
an = 0.95;
tb = 3.33;
tn = 3.33;
amax = 50; #greatest allowed age

t0 = time(); 
STATIC = true;
RANDOMSTART = true;
DOOVER = 1;	

#test some algorithm conditions:
if !(0 < en || en < eb || eb < 1)
    error("en and/or eb definitions are wrong. They are as: 0<en<eb<1.")
end
# (1)
# pick n1 and n2 from data
ni1 = 1; 
ni2 = 2; 
if RANDOMSTART
    n = randperm(size(data,2));
    ni1 = n[1];
    ni2 = n[2];
end
n1 = data[:,ni1]; n2 = data[:,ni2];

#println(strcat("Initial parameters ","n1 =  ",num2str(ni1)," n2 =  ",num2str(ni2)))

A = zeros(size(n1,1),maxnodes);
    A[:,[1,2]] = hcat(n1, n2)

# (2)
# initialize empty set C

C = spzeros(maxnodes,maxnodes);
C_age = C;

r = 3; 
h = zeros(1,maxnodes);
datasetsize = size(data,2);

#some variables to display the graphs
activations = [];
nodecount = [];
epoch = 1;

### SPEEDUP CHANGE
if STATIC
    hizero = hi(0)*ones(1,maxnodes);
    hszero = hs(0);
else
    timetime = 0;
end
OldA = A;
# start of the loop
for epochscounter = 1:DOOVER
for k = 1:datasetsize #step 1
	#global A
        eta = data[:,k]; # this the k-th data sample
        ws, (), s, t, () = findnearest(eta, A); #step 2 and 3
    if C[s,t]==0 #step 4
        C = spdi_bind(C,s,t);
    else
        C_age = spdi_del(C_age,s,t);
    end
    a = exp(-norm(eta-ws)); #step 5
   
    neighbours = findneighbours(s, C);

    num_of_neighbours = size(neighbours,1);
  
    if a < at && r <= maxnodes #step 6
        wr = 0.5*(ws+eta); #too low activity, needs to create new node r
        A[:,r] = wr;
        C = spdi_bind(C,t,r);
        C = spdi_bind(C,s,r);
        C = spdi_del(C,s,t);
        r = r+1;
    else #step 7
        for j = 1:num_of_neighbours # check this for possible indexing errors
            i = neighbours[j];
            wi = A[:,i];
            A[:,i] = wi + en*h[i]*(eta-wi);
        end
        A[:,s] = ws + eb*h[s]*(eta-ws); 
    end
    #step 8 : age edges with end at s
    #first we need to find if the edges connect to s
    
    for j = 1:num_of_neighbours # check this for possible indexing errors
           i = neighbours[j];
           C_age = spdi_add(C_age,s,i);
    end
          
    #step 9: again we do it inverted, for loop first
    #### this strange check is a speedup for the case when the algorithm is static
    if STATIC # skips this if algorithm is static
        h = hizero;
        h[s] = hszero;
    else
        for i = 1:r 
            h[i] = hi(time); 
        end
        h[s] = hs(timetime);
        timetime = (time - t0)*1; 
    end    
   
    #step 10: check if a node has no edges and delete them
    if r>2 # don't remove everything
        C, C_age  = removeedge(C, C_age);  
        C, A, C_age, h, r  = removenode(C, A, C_age, h, r);  #inverted order as it says on the algorithm to remove points faster
    end
    #activations = vcat(activations, a);
    epoch += 1;   
    
end
end
return A,C,ni1,ni2 
end

function spdi_add(sparsemat, a, b) #increases the number 
sparsemat[a,b] = sparsemat[a,b] + 1; 
sparsemat[b,a] = sparsemat[a,b] + 1;
return sparsemat
end

function spdi_bind(sparsemat, a, b) # adds a 2 way connection
sparsemat[a,b] = 1; 
sparsemat[b,a] = 1;
return sparsemat
end

function spdi_del(sparsemat, a, b) # removes a 2 way connection
sparsemat[a,b] = 0;
sparsemat[b,a] = 0;
return sparsemat

end

function S(t)
    X = 1;
return X
end

function hs(t)
global h0,ab,tb 
X = h0 - S(t)/ab*(1-exp(-ab*t/tb));
return X
end

function hi(t)
global h0, an, tn 
X = h0 - S(t)/an*(1-exp(-an*t/tn));
return X
end



