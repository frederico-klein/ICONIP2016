function allskel = generate_falling_stick(numsticks)
    stickmodel = 'skel25'; % 'rod', 'skel25', 'skel15'
    thetanoisepower = 0.01;
    translationnoisepower = 1;
    floorsize = 1500;
for kk = 1:numsticks
    num_of_points_in_stick = 25;
    l = (1.6+rand()*.3)*1000;    
    for akk = [0,1]        
        startlocation = floorsize*[rand(), 0.01*rand(), rand()];
        phi = 2*pi*rand();
        phinoisepower = 0.1*rand;
        initial_velocity = -1*rand();        
        if akk
            act = 'Fall';
            % from http://www.chem.mtu.edu/~tbco/cm416/MatlabTutorialPart2.pdf and
            % from http://ocw.mit.edu/courses/mechanical-engineering/2-003j-dynamics-and-control-i-spring-2007/lecture-notes/lec10.pdf
            % the equation from the falling stick is
            %
            % -m*g*l/2*cos(t) = (Ic+m*l^2/4*cos(t)^2)*tdd - m*l^2/4*cos(t)*sin(t*td^2)
            %
            % tdd = diff(td)
            % td = diff(t)            
            testOptions = odeset('RelTol',1e-3,'AbsTol', [1e-4; 1e-2]);
            notsatisfiedwithmodel = true;
            while(notsatisfiedwithmodel)
            [t,x] =     ode45(@stickfall, [0 2+1.5*rand()], [pi/2;initial_velocity], testOptions);
            %%% resample to kinect average sample rate, i.e. 15 or 30 hz
            x = resample(x(:,1),t,30);            
            %%% upon visual inpection we see that the beginnings and ends
            %%% of the results from ode45 sequence are very noisy, possibly
            %%% due to the unnatural constraints on the differential
            %%% equation mode. Some doctoring is required:            
            x(1,:) = x(2,:)+0.01*rand(); %%% fixing initial point
            %fixing ends
            diffx = abs(diff(x));
            for i = length(diffx):-1:3
                if all([diffx(i-2), diffx(i-1), diffx(i)]<0.07) %this was done on trial and error basis
                    x = x(1:i);
                    if abs(x(end))<0.1||abs(x(end)-pi)<0.1 %%it has to end in a natural resting angle
                        notsatisfiedwithmodel = false;
                    end
                    break
                end
            end
            end
            padding = x(end).*ones(round(130*rand()),1);
            padding = padding+thetanoisepower*rand(size(padding));
            x = [x;padding];
            phinoise = zeros(size(x));
            translationnoise = translationnoisepower*zeros(size(x,1),3);
            [skel, vel] = construct_skel(x,l,num_of_points_in_stick ,startlocation, translationnoise, phi, phinoise, stickmodel);            
        else
            act = 'Walk';
            %%% non falling activity
            x = pi/2*ones(90+round(25*rand()),1)+thetanoisepower; 
            phinoise = phinoisepower*rand(size(x));
            %%% the walk
            t = linspace(0,1,length(x));
            realtransx = 2*sin(phi)*t*floorsize;
            realtransy = 0*t*floorsize;
            realtransz = 2*cos(phi)*t*floorsize;
            translationnoise = 0*translationnoisepower*rand(size(x,1),3)+[realtransx; realtransy; realtransz]'; 
            [skel, vel] = construct_skel(x, l, num_of_points_in_stick, startlocation, translationnoise , phi, phinoise, stickmodel);            
        end   
        construct_sk_struct = struct('x',x,'l',l,'num_points', num_of_points_in_stick,'startlocation',startlocation,'phi',phi);
        jskelstruc = struct('skel',skel,'act_type', act, 'index', kk, 'subject', kk,'time',[],'vel', vel, 'construct_sk_struct', construct_sk_struct);
        if exist('allskel','var') % initialize my big matrix of skeletons
            allskel = cat(2,allskel,jskelstruc);
        else
            allskel = jskelstruc;
        end
    end
end
end
function dx = stickfall(t,x)
m = 70;
g = 9.8;
l = 1.6;
t = 0;
Ic = 1/3*m*l^2;%% for a slender rod rotating on one end
x1 = x(1);
x2 = x(2);
if ((x1 < 0)&&x2<0)||((x1> pi)&&x2>0)
    dx1 = -0.5*x2; 
else
    dx1 = x2;
end
dx2 = (m*l^2/4*cos(x1*x2^2) -m*g*l/2*cos(x1))/(Ic+m*l^2/4*cos(x1)^2);
dx = [dx1;dx2];
end
function [stickstick,stickvel] = construct_skel(thetha, l, num_of_points_in_stick, displacement, tn, phi, phinoise, stickmodel)
bn = [rand(), rand(), rand()]/10; 
simdim = size(thetha,1);
stickstick = zeros(num_of_points_in_stick,3,simdim);
stickvel = stickstick; 
switch stickmodel
    case 'rod'
        for i=1:simdim
            dpdp =  displacement+tn(i,:);
            tt=thetha(i);
            PHI = phi+phinoise(i);            
            stickstick(1,:,i) = dpdp-l/2*cos(tt)*[cos(PHI) 0 sin(PHI)];
            for j = 2:num_of_points_in_stick
                stickstick(j,:,i) = ([cos(tt)*cos(PHI), sin(tt), cos(tt)*sin(PHI)]+bn)*l*j/num_of_points_in_stick+dpdp-l/2*cos(tt)*[cos(PHI) 0 sin(PHI)];
            end
        end
    case 'skel25'
        num_of_points_in_stick = 25;
        %%%% skeleton model was obtained after using generate_skel_data
        %protoskel = allskel1(3).skel(:,:,1) -repmat(mean(allskel1(3).skel(:,:,1)),25,1);
        prot = load('protoskel.mat');
        height = 1552;
        if ~isfield(prot,'protoskel')
            error('Problems to load protoskel.mat: skeleton model not found.')
        end
        for i=1:simdim
            dpdp =  displacement+tn(i,:);
            tt=thetha(i);
            PHI = phi+phinoise(i);
            askel = rotskel(prot.protoskel2+repmat([0 height/2 0],num_of_points_in_stick,1),0,PHI,pi/2-tt);
            for j = 1:num_of_points_in_stick
                stickstick(j,:,i) = askel(j,:)/height*l+dpdp-l/2*cos(tt)*[cos(PHI) 0 sin(PHI)];
            end
        end
end
for i = 2:simdim
    stickvel(:,:,i-1) = stickstick(:,:,i)-stickstick(:,:,i-1);
end
end