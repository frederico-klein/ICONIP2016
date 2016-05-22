function plotgwr(A,C)
if size(A,1) == 147 || size(A,1) == 150
    A = rebuild(A);
end

row,col = findnz(C);
ax = A[1,row];
ay = A[2,row];
bx = A[1,col];
by = A[2,col];

X = reshape([ax;bx;NaN*ones(size(ax))],size(ax,2)*3,1)'; 
Y = reshape([ay;by;NaN*ones(size(ax))],size(ax,2)*3,1)'; 

if size(A,1)>=3&size(A,1)<75&size(A,1)!=72
    az = A(3,row);
    bz = A(3,col);
    Z = reshape([az;bz;NaN*ones(size(ax))],size(ax,2)*3,1)';
    plot3(X,Y,Z, 'b')
elseif size(A,1) == 75||size(A,1) == 72
    if size(A,1) == 72
        tdskel = zeros(24,3,size(A,2));
        for k = 1:size(A,2)
            for i=1:3
                for j=1:24
                    tdskel(j,i,k) = A(j+24*(i-1),k);
                end
            end
        end
        tdskel = cat(1,zeros(1,3,size(A,2)), tdskel);     
    else
        tdskel = zeros(25,3,size(A,2));
        for k = 1:size(A,2)
            for i=1:3
                for j=1:25
                    tdskel(j,i,k) = A(j+25*(i-1),k);
                end
            end
        end
    end
    if all(size(tdskel) != [25,3,size(A,2)])
        error("wrong skeleton building procedure!")
    end
    #q = size(squeeze(tdskel(1,:,row)),2);
    
    #quattro = cat(4, tdskel(:,:,row),tdskel(:,:,col));
    moresticks = [];
    
    #moresticks = zeros(3,3*size(row));
    for i=1:size(tdskel,1)
        for j=1:size(row)
            moresticks = cat(2,moresticks,[tdskel(i,:,row(j));tdskel(i,:,col(j)); [NaN NaN NaN]]');
        end
    end
    
    SK = skeldraw(A(:,1),0);
    for i = 2:size(A,2)
       SK = [SK,skeldraw(A(:,i),0)];      
    end
    T = [SK,moresticks];
    plot3(T(1,:),T(2,:),T(3,:))
    
else
    plot(X',Y', "b")    
end
#set(gca,"box","off")
end
function rebuild(A) 
a = size(A,1)/3;
c = size(A,2);
 
B = reshape(A,a,3,c); 

if a == 49
    A = B(1:24,:,:);
    A = reshape(A,72,c);
else
    error("not implemented for this size")
end
return A 
end
