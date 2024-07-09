%game_brickwalls
clear
clc
close all

%IDEAS/NOTES
% - start date was about 5/13/2020
% - make main menu screen and start button
% - make adjustable sensitivities
% - different levels (5 or 10 depending on how much I care...probably 5)
% - Scale explosion animation size based on size of bricks
% - what happens if you beat a level? the last level? confetti or sum
% - what happens when you lose all your lives?
% - when the bricks hit the bottom of the screen you should lose completely

%CURRENT BUG
% - none of the animations will finish if you die in the middle of them
% (both explosions and laser)...I reckon either delete all animations at
% death or let them finish post-death...maybe it depends on which one

%% SETUP

%Get screensize
screensize = get(0,'ScreenSize');
figwidth = screensize(3)/2;
figheight = screensize(4)-120;

%Create blue figure that has a KeyPressFcn with a function handle
%keyboardFunction
brickwallsFigure = figure('Position',[0,40,figwidth,figheight],...
    'color','blue','KeyPressFcn',@keyboardFunction);

%Ratios of axes positions to fig window positions
xMinAxesRat = 0;
xMaxAxesRat = 1;
yMinAxesRat = 0;
yMaxAxesRat = 1;
%Axes mins and maxes
xMin = -5;
xMax = 105;
yMin = -20;
yMax = 105;
%Create axes
brickwallsAxes = axes('XLim',[xMin xMax],'YLim',[yMin yMax],...
    'color','black',...
    'XTickLabels',[],'YTickLabels',[],...
    'position',[xMinAxesRat,yMinAxesRat,xMaxAxesRat,yMaxAxesRat]);
grid on
%Pixels to axes units
pixperunit = figwidth/(xMax-xMin);
%Create border patch
bThickness = 5;
%Create coords
borderX = [xMin,xMin,xMax,xMax,xMax-bThickness,xMax-bThickness,...
    xMin+bThickness,xMin+bThickness,xMax-bThickness,xMax-bThickness,...
    xMin+bThickness,xMin+bThickness,xMax-bThickness,xMax-bThickness,...
    xMin+bThickness];
borderY = [yMin,yMax,yMax,yMin,yMin,yMax-bThickness,yMax-bThickness,...
    -5,-5,-8,-8,-17,-17,yMin,yMin];

%% INITIALIZE

%GLOBALIZE
global BlockCenter dBlockCenter bwidth G_time max_G_time lasergun_on L_time

%SIGNAL VARIABLES
stop = 0; %represents whether game continues or not
canShift = 1; %represents whether shift can be done
auto = 1;
mouse = 2;
keys = 3;
changeD = 1; %represents whether block can change ball's direction
mode = mouse; %represents which control mode is active
B_exploding = 0; %represents whether a Boom explosion is happening
G_exploding = 0; %represents whether a Ghost explosion is happening
lasergun_on = 0; %represents whether lasergun powerup is on
shots_left = 5; %number of shots available for lasergun power up
life_down = 0; %represents whether life brick has been hit
shiftDeath = 0; %represents whether death was caused by shift
playing = 1; %represent if game is being played

%TIME DATA
t = 0; %time variable
p = 0.015; %pause variable, IMPORTANT: speedChange function depends on this
           %value, it cannot be changed to just anything
numIT = 0; %number of iterations counter
N = 1; %iteration counter for explosion animation
G_time = 0; %number of iterations since striking Ghost Brick
max_G_time = 400; %number iterations before G_explosion automatically happens
L_time = 0; %iteration counter for laser animation
H_time = 0; %iteration counter for falling heart animation

%EXPLOSION
%I needed to make these variables exist as placeholders for
%outputs/inputs, they have abritrary values until they come into play
offx = 0; 
offy = 0;

%COLOR DATA
darkred = [0.9,0,0];
brightred = [1,0,0];
lightgray = [0.8,0.8,0.825]; %with subtle blue tint
gold = [1,0.85,0];
black = [0,0,0];
white = [1,1,1];
brightblue = [0,0,1];
brightgreen = [0,1,0];
darkgreen = [0,0.5,0];
pink = [1,0.4,0.6];
orange = [1,0.5,0];
purple = [0.7,0,0.7];
blue = [0,0,1];
BasicBrickColor = brightred;
StrongBrickColor = darkred;
SteelBrickColor = lightgray;
BoomBrickColor = gold;
GhostBrickColor = white;
LifeBrickColor = pink;
LaserBrickColor = blue;
BallColor = white;

%BRICK DATA
numBricksAcross = 7;
numBricksDown = 6;
brickWidth = 100/numBricksAcross; %width of bricks(DEPENDENT)
brickDepth = 8.75; %depth of bricks (MANUAL)
%Coords for regular bricks
brickXCoords = [0,brickWidth,brickWidth,0];
brickYCoords = [0,0,brickDepth,brickDepth];
shift = 0; %initial shift
dshift = -2; %change in shift after each block hit
%Coords for cracked bricks
crackedbrickXCoords = [0,0.7*brickWidth,0.65*brickWidth,0.8*brickWidth,...
    0.7*brickWidth,0.8*brickWidth,brickWidth,brickWidth,...
    0.4*brickWidth,0.425*brickWidth,0.35*brickWidth,0.4*brickWidth,...
    0.35*brickWidth,0,0,0.075*brickWidth,0];
crackedbrickYCoords = [0,0,0.35*brickDepth,0.7*brickDepth,0.35*brickDepth,...
    0,0,brickDepth,brickDepth,0.8*brickDepth,0.6*brickDepth,...
    0.8*brickDepth,brickDepth,brickDepth,0.375*brickDepth,...
    0.3*brickDepth,0.225*brickDepth];
numBricks = numBricksAcross*numBricksDown; %number of bricks (10 x 4 grid)
n = 1; %counter
vertBricksLeft = numBricksDown; %represents number of bricks left
                               %in "vertical section"
for n = 2:numBricksAcross
vertBricksLeft = [vertBricksLeft,numBricksDown]; %"add" another element
end
%Brick types (these numbers are insignificant.  Its just easier to give
%number values that string variable values)
Nonexistent = 0;
Basic = 1;
Strong = 2;
StrongCracked = 3;
Boom = 4;
Steel = 5;
Ghost = 6;
Laser = 7;
Life = 8;

%BALL DATA
minX = 0;
maxX = 100;
minY = 0;
maxY = 100;
BallVel = 0.9*0.75*0.75*[1,1]; %velocity vector of ball
BallVel0 = BallVel; %original velocity vector value
BallVel1_org = BallVel(1); %base value of x-velocity
markersize = 70; %size of Ball
BallRad = markersize/35; %radius of Ball
rnumX = round(100-2*BallRad); %upper limit of randomized ball coordinate
rnumY = rnumX-round(numBricksDown*brickDepth);

%Direction signal variables
left = -1;
right = 1;
down = -1;
up = 1;
%Direction change signal variables
inY = 0;
inX = 1;
%Initial directions
xDirection = right;
yDirection = up;

%BLOCK DATA
bwidth = 20; %width of Block
bwidthpixels = bwidth*pixperunit; %width in pixels
dBlockCenter = 4; %change in position when button is pressed
rnum = round(100-bwidth/2);
linewidth = 6; %width of pongBlock
BlockThickness = linewidth/9.5; %thickness of Block                      

%POWER UP DATA
old_shots_left = 0; %equals shots_left if ghost powerup is activated
laserwidth = 8;
meterwidth = 8;
lasermeterdist = 5;
heartdist = 6; %distance between heart centers
lives = 3; %number of lives
%Create coords for heart patches
[heartX,heartY] = heart_coords;
heartShift = -0.5; %change in y position of heart after each iteration

%% START OF GAME
    %Create animation patch coordinates for later
    %Create coords of expl
    [expl_org] = create_expl;
    %Create coords of expl2
    [expl2_org] = create_expl2;
    %Create coords of epxl3
    [expl3a_org,expl3b_org,expl3c_org] = create_expl3;
    %Same thing for G_expl
    [G_expl_org] = G_create_expl;
    [G_expl2_org] = G_create_expl2;
    [G_expl3a_org,G_expl3b_org,G_expl3c_org] = G_create_expl3;

%Main Menu animation
[B1_p,R1_p,I_p,C_p,K1_p,B2_p,R2_p,E1_p,A_p,K2_p,E2_p,R3_p,tBall_p] = animatebricks;
pause(2) %for testing
%Delete title screen
delete(B1_p)
delete(R1_p)
delete(I_p)
delete(C_p)
delete(K1_p)
delete(B2_p)
delete(R2_p)
delete(E1_p)
delete(A_p)
delete(K2_p)
delete(E2_p)
delete(R3_p)
delete(tBall_p)
pause(0.5)

while playing == 1
%% LEVEL SETUP

%Create border
border = patch(borderX,borderY,'b');

%Special bricks
special_on = 1;
if special_on == 1
%Make one random brick Boom
%Randomized row and column of Boom brick's position
rBoom = 1+randi(numBricksDown-2); %prevents r from being on the end 
cBoom = 1+randi(numBricksAcross-2); %prevents c from being on the end
bricksStatus(rBoom,cBoom) = Boom;
BoomBrickPos = [rBoom,cBoom]; %save position of Boom Brick

%Make one random brick Ghost
diff = 0; %represents whether GhostBrickPos is same as BoomBrickPos
while diff ~= 1
rGhost = randi(numBricksDown);
cGhost = randi(numBricksAcross);
GhostBrickPos = [rGhost,cGhost]; %save position of Ghost Brick
if GhostBrickPos ~= BoomBrickPos
    diff = 1;
end
end
bricksStatus(rGhost,cGhost) = Ghost;

%Make one random brick Laser
diff = 0; 
while diff ~= 1
rLaser = randi(numBricksDown);
cLaser = randi(numBricksAcross);
LaserBrickPos = [rLaser,cLaser]; %save position of Laser Brick
if LaserBrickPos ~= BoomBrickPos
    if LaserBrickPos ~= GhostBrickPos
        diff = 1;
    end
end
end
bricksStatus(rLaser,cLaser) = Laser;

%Make one random brick Life
diff = 0; 
while diff ~= 1
rHeart = randi(numBricksDown);
cHeart = randi(numBricksAcross);
LifeBrickPos = [rHeart,cHeart]; %save position of Laser Brick
if LifeBrickPos ~= BoomBrickPos
    if LifeBrickPos ~= GhostBrickPos
        if LifeBrickPos ~= LaserBrickPos
            diff = 1;
        end
    end
end
end
bricksStatus(rHeart,cHeart) = Life;

end %if special_on == 1

pause(0.25)
%Create initial brick patches
for r = 1:numBricksDown
    for c = 1:numBricksAcross
    brickCornerXPos(r,c) = brickWidth*(c-1);
    brickCornerYPos(r,c) = 100-brickDepth*r+shift;
    %Create "original" variable for brickCornerYPos
    brickCornerYPos_org(r,c) = 100-brickDepth*r; %no shift in this array
    if r == rBoom && c == cBoom
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),BoomBrickColor);
    elseif r == rGhost && c == cGhost
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),GhostBrickColor);
    elseif r == rLaser && c == cLaser
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),LaserBrickColor);
    elseif r == rHeart && c == cHeart
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),LifeBrickColor);
    else
    bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),StrongBrickColor);
    bricksStatus(r,c) = 2;
    end
    pause(0.05)
    end
end

%Create heart patches
for n = 1:lives
    pause(0.25)
    %Create patch
    hearts(n) = patch(heartX+minX+2/3*bThickness+heartdist*(n-1),heartY-15,pink);
end

%Delete rows and columns
yes = 1;
if yes == 1
%Delete outside columns
for n = 1:numBricksDown
    %Rightmost column
%    bricksStatus(n,numBricksAcross) = 0;
%    delete(bricks(n,numBricksAcross))
    %Leftmost column
%    bricksStatus(n,1) = 0;
%    delete(bricks(n,1))
end
%Delete bottom and top rows
for n = 1:numBricksAcross
    %Bottom row
%    delete(bricks(numBricksDown,n))
%    bricksStatus(numBricksDown,n) = 0;
    %Top row
%    delete(bricks(1,n))
%    bricksStatus(1,n) = 0;
end
end

pause(0.25)
%Create Block patch
BlockCenter = bwidth/2+randi(rnum); %center of position of Block
Block = line([BlockCenter-bwidth/2,BlockCenter+bwidth/2],...
    [0 0],'linewidth',linewidth,'color',brightgreen);

%% LOOP

while lives > 0
countdown(white); %countdown before game starts

%Spawn Ball
BallPos = [BallRad+randi(rnumX),BallRad+randi(rnumY)];
%The following start position allows for corner scenario to be recreated
%BallPos = [80 34.5];
BallPos = [80 30-20];
BallPos0 = BallPos; %saves initial position, helps with debugging
Ball = line(BallPos(1),BallPos(2),'marker','.',...
    'markersize',markersize,'color',BallColor);

%Initial Calculations
%Calculate "horizontal section" and "vertical section," using function
[vertSect,horSect] = locateBall(BallPos,...
numBricksAcross,numBricksDown,vertBricksLeft,brickCornerXPos,...
brickCornerYPos,brickDepth,brickWidth,shift);
%Calculate borders
[minX,maxX,minY,maxY] = calcBorders(BallPos,numBricksAcross,...
numBricksDown,brickWidth,brickDepth,bricksStatus,brickCornerXPos,...
brickCornerYPos,maxY,vertSect,horSect,shift,G_time,max_G_time);
    
while stop ~= 1
    %OUTPUTS FOR DEBUGGING
    
    
    
    
    %Update numBricksDown
    [numBricksDown] = update_numBricksDown(numBricksDown,...
    numBricksAcross,bricksStatus);
    
%Check for conditions
if BallPos(2) < 100-brickDepth*numBricksDown+shift %ball is beneath bricks
    %change direction if ball is too far left or right
    %switch to right
    if BallPos(1)-BallRad < 0 && xDirection == left
        BallVel(1) = -BallVel(1);
        xDirection = right;
    %switch to left
    elseif BallPos(1)+BallRad > 100 && xDirection == right
        BallVel(1) = -BallVel(1);
        xDirection = left;
    end
    %switch to down
    if BallPos(2)+BallRad > maxY && yDirection == up
        BallVel(2) = -BallVel(2);
        change = inY;
        [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left] = brickReact(numBricksDown,...
        horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
        StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
        crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
        up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
        Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
        BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left);
        yDirection = down;
    end
    %check whether block is underneath ball
    if BallPos(2)-BallRad-BlockThickness < 0 && yDirection == down
        if abs(BallPos(1) - BlockCenter) < bwidth/2
            BallVel(2) = -BallVel(2);
            yDirection = up;
            %THE FOLLOWING FUNCTION (which isn't a function yet) WORKS
            %CORRECTLY

            if changeD == 1 %block can change ball's direction
            [BallVel,xDirection] = calc_xVel(BallVel1_org,BallVel,...
                BallPos,BlockCenter,bwidth,right,left);
            end
            
           %Shift bricks down
           if canShift == 1 %bricks can be shifted
            [bricks,brickCornerYPos,shift,stop,shiftDeath] = shiftBricks(numBricksDown,...
            numBricksAcross,brickCornerYPos_org,bricksStatus,Basic,...
            Strong,Boom,Steel,brickXCoords,brickYCoords,brickCornerXPos,...
            brickCornerYPos,crackedbrickXCoords,crackedbrickYCoords,...
            shift,bricks,StrongCracked,dshift,stop,BlockThickness,Ghost,...
            Laser,Life,shiftDeath);
           end
        else
            stop = 1;
        end
    end
elseif BallPos(2) > 100+shift %ball is above bricks
    %switch to right
    if BallPos(1)-BallRad < minX && xDirection == left
        BallVel(1) = -BallVel(1);
        xDirection = right;
    end
    %switch to left
    if BallPos(1)+BallRad > maxX && xDirection == right
        BallVel(1) = -BallVel(1);
        xDirection = left;
    end
    %switch to down
    if BallPos(2)+BallRad > maxY && yDirection == up
        BallVel(2) = -BallVel(2);
        yDirection = down;
    end
    %switch to up
    if BallPos(2)-BallRad < minY && yDirection == down
        BallVel(2) = -BallVel(2);
        change = inY;
        [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left] = brickReact(numBricksDown,...
        horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
        StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
        crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
        up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
        Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
        BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left);
        yDirection = up;
    end
else %ball is within bricks
    %switch to left
    if BallPos(1)+BallRad > maxX && xDirection == right
        BallVel(1) = -BallVel(1);
        change = inX;
        if vertSect ~= numBricksAcross %ball is not at rightmost "vertical section"  
            [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left] = brickReact(numBricksDown,...
            horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
            StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
            crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
            up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
            Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
            BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left);
        end
        xDirection = left;
    end
    %switch to right
    if BallPos(1)-BallRad < minX && xDirection == left
        BallVel(1) = -BallVel(1);
        change = inX;
        if vertSect ~= 1 %ball is not at leftmost "vertical section"
            [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left] = brickReact(numBricksDown,...
            horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
            StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
            crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
            up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
            Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
            BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left);
        end
        xDirection = right;
    end
    %switch to down
    if BallPos(2)+BallRad > maxY && yDirection == up
        BallVel(2) = -BallVel(2);
        change = inY;
        if horSect ~= 1 && horSect ~= 0 %ball is not at top "horizontal
            %section" nor above bricks
            %Let brick react
            [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left] = brickReact(numBricksDown,...
            horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
            StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
            crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
            up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
            Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
            BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left);
        end
        yDirection = down;
    end
    %switch to up
    if BallPos(2)-BallRad < minY && yDirection == down
        if minY == 0 %min is the block, not a brick
            %check whether block is underneath ball
            if BallPos(2)-BallRad-BlockThickness < 0
                if abs(BallPos(1) - BlockCenter) < bwidth/2
                    BallVel(2) = - BallVel(2);
                    yDirection = up;
                    %Shift bricks down
                    [bricks,brickCornerYPos,shift,stop,shiftDeath] = shiftBricks(numBricksDown,...
                    numBricksAcross,brickCornerYPos_org,bricksStatus,Basic,...
                    Strong,Boom,Steel,brickXCoords,brickYCoords,brickCornerXPos,...
                    brickCornerYPos,crackedbrickXCoords,crackedbrickYCoords,...
                    shift,bricks,StrongCracked,dshift,stop,BlockThickness,Ghost,...
                    Laser,Life,shiftDeath);
                else
                    stop = 1;
                end
            end
            
        %THE FOLLOWING USED TO BE AN "ELSE" STATEMENT, NOT "ELSEIF."  THIS
        %IS PART OF DEBUGGING AND MAY REMAIN PERMANENT
        elseif yDirection == down %min is a brick
            BallVel(2) = -BallVel(2);
            change = inY;
            if horSect ~= numBricksDown %ball is not at bottommost "horizontal
                                        %section"
                [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left] = brickReact(numBricksDown,...
                horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
                StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
                crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
                up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
                Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
                BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left);
            end
        end
        yDirection = up;
    end
end

%check for corner scenario
if horSect ~= 0 && horSect < numBricksDown+1 && (G_time == 0 || G_time > max_G_time)%ball is within bricks
    if bricksStatus(horSect,vertSect) ~= 0 %ball is inside of a brick
        if bricksStatus(horSect,vertSect) == Basic ||...
           bricksStatus(horSect,vertSect) == StrongCracked
            %Delete brick
            bricksStatus(horSect,vertSect) = 0;
            delete(bricks(horSect,vertSect));
        elseif bricksStatus(horSect,vertSect) == Strong
            %Crack brick and change brick type
            delete(bricks(horSect,vertSect))
            bricks(horSect,vertSect) = patch(crackedbrickXCoords...
            +brickCornerXPos(horSect,vertSect),...
            crackedbrickYCoords+brickCornerYPos(horSect,vertSect),StrongBrickColor);
            bricksStatus(horSect,vertSect) = StrongCracked;
        elseif bricksStatus(horSect,vertSect) == Boom
            %Brick explodes and destroys all bordering bricks that exist
            %Check for existence **only works if brick is not on edge
            for R = horSect-1:horSect+1
                for C = vertSect-1:vertSect+1
                    if bricksStatus(R,C) ~= 0
                        bricksStatus(R,C) = 0;
                        delete(bricks(R,C))
                    end
                end
            end
            %Change B_exploding variable
            B_exploding = 1;
            %Rename horSect and vertSect
            row = horSect;
            col = vertSect;
            %Define shifts
            offx = brickCornerXPos(row,col)+brickWidth/2;
            offy = brickCornerYPos(row,col)+brickDepth/2;
        elseif bricksStatus(horSect,vertSect) == Ghost
            if lasergun_on ~= 0
                lasergun_on = 0;
                old_shots_left = shots_left;
                shots_left = 0;
                delete(lasergun_p)
            end
            G_time = 1;
            delete(bricks(horSect,vertSect))
            bricksStatus(horSect,vertSect) = 0;
        elseif bricksStatus(horSect,vertSect) == Laser
            lasergun_on = 1;
            delete(bricks(horSect,vertSect))
            bricksStatus(horSect,vertSect) = 0;
        elseif bricksStatus(horSect,vertSect) == Life
            delete(bricks(horSect,vertSect))
            bricksStatus(horSect,vertSect) = 0;
            life_down = 1;
        end
        %Change velocities and directions
        BallVel(1) = -BallVel(1);
        BallVel(2) = -BallVel(2);
        xDirection = -xDirection;
        yDirection = -yDirection;
    end
end

    %Delete and reset lasergun
    if shots_left == 0 && lasergun_on > 0 && L_time < 2 %ghost power up has become active
        %Reset everything, delete patch
            delete(lasergun_p)
            lasergun_on = 0;
            L_time = 0;
            for n = 1:old_shots_left
                disp('ay')
                delete(lasermeter_p(6-n))
            end
            shots_left = 5;
    end
    %Lasergun animation (bottom layer patch, it comes before other patch
    %functions)
    if L_time == 2 && shots_left > 0
        %Delete laser meter
        delete(lasermeter_p(6-shots_left))
        %Calculate column of Block
        for n = 1:numBricksAcross
            x = BlockCenter - brickCornerXPos(1,n);
            if x < brickWidth && x >= 0
                c_Block = n;
            end
        end
        laserY = 100; %set laserY
        %Calculate maxY based on existence of bricks in c_Block
        for ROW = 1:numBricksDown
            if bricksStatus(ROW,c_Block) ~= Nonexistent
                laserY = brickCornerYPos(ROW,c_Block); %set laserY
                target_row = ROW;
            end
        end
        laserX = BlockCenter; %set laserX using initial Block position
        laser_p = line([laserX,laserX],[BlockThickness,0.05*laserY],...
            'linewidth',laserwidth,'color',blue);
    elseif L_time == 5
        delete(laser_p)
        laser_p = line([laserX,laserX],[0.05*laserY,0.95*laserY],...
            'linewidth',laserwidth,'color',blue);
    elseif L_time == 8
        delete(laser_p)
        laser_p = line([laserX,laserX],[0.95*laserY,1*laserY],...
            'linewidth',laserwidth,'color',blue);
    elseif L_time == 11
        delete(laser_p)
        %Delete brick if it exists
        if laserY ~= 100
            delete(bricks(target_row,c_Block))
            bricksStatus(target_row,c_Block) = 0;
        end
        L_time = 0; %reset L_time
        if shots_left <= 1
            lasergun_on = 0; %turn off lasergun
            delete(lasergun_p) %delete lasergun
            shots_left = 5; %reset shots_left
        else
            shots_left = shots_left-1;
        end
    end
    
    %Change ball to ring
    if G_time == 1
        [Ball,xCoords,yCoords] = Ball2Ring(BallRad,Ball,BallPos);
    end
    %Change ring to ball
    if G_time == max_G_time
        [Ball] = Ring2Ball(BallRad,Ball,BallPos,markersize,BallColor);
    end
    
    %Update ball's position
    BallPos = BallPos+BallVel;
    if G_time == 0 || G_time > max_G_time
    set(Ball,'XData',BallPos(1),...
             'YData',BallPos(2));
    elseif G_time < max_G_time
    set(Ball,'XData',xCoords+BallPos(1),...
             'YData',yCoords+BallPos(2));
    end
    
    %Boom Explosion animation (must follow the ball reposition so the explosion
    %is always "on TOP" of the ball)
    if B_exploding == 1
        %Rename r and c
        row = r;
        col = c;
        %Use functions to animate
        if N == 1
            [expl_p,in_expl_p] = A_animate_B_expl(expl_org,offx,offy);
        end
        if N > 1 && N < 11
            B_animate_B_expl(expl_p,in_expl_p,expl_org,N,offx,offy);
        end
        if N == 11
            [expl2_p] = C_animate_B_expl(expl2_org,offx,offy);
        end
        if N > 11 && N < 22
            D_animate_B_expl(expl2_p,expl2_org,N,offx,offy)
        end
        if N == 22
            [expl3a_p,expl3b_p,expl3c_p] = E_animate_B_expl(expl_p,in_expl_p,expl2_p,expl3a_org,expl3b_org,...
            expl3c_org,offx,offy);
        end
        if N > 22 && N < 34
            F_animate_B_expl(expl3a_p,expl3b_p,expl3c_p,expl3a_org,expl3b_org,...
            expl3c_org,N,offx,offy);
        end
        if N == 34
            G_animate_B_expl(expl3a_p,expl3b_p,expl3c_p);
        end
        if N == 35
            B_exploding = 0; %turn off B_exploding
        end
        N = N+1 %change n value for next iteration
    end
    
    %Ghost meter
    if G_time == 1
        %Create initial patch
        G_meter_p = line([73+20*G_time/max_G_time,98],[-12.5,-12.5],...
            'linewidth',meterwidth,'color',white);
    elseif G_time > 0 && G_time < max_G_time
        %Update patch
        delete(G_meter_p)
        G_meter_p = line([78+20*G_time/max_G_time,98],[-12.5,-12.5],...
            'linewidth',meterwidth,'color',white);
    elseif G_time == max_G_time
        delete(G_meter_p)
    end
    
    %Ghost explosion animation
    if G_time >= max_G_time || G_exploding == 1
            %Rename N
            A = G_time-(max_G_time-1);
            %Use functions to animate
            if A == 1
                %Destroy brick in Ball's position if existent
                if horSect ~= 0 && horSect <= numBricksDown %Ball is within bricks
                if bricksStatus(horSect,vertSect) == Boom
                    %Brick explodes and destroys all bordering bricks that exist
                    %Check for existence **only works if brick is not on edge
                    for R = horSect-1:horSect+1;
                        for C = vertSect-1:vertSect+1;
                            if bricksStatus(R,C) ~= 0
                                bricksStatus(R,C) = 0;
                                delete(bricks(R,C))
                            end
                        end
                    end
                    %Change B_exploding variable
                    B_exploding = 1;
                    %Rename r and c
                    row = horSect;
                    col = vertSect;
                    %Define shifts
                    offx = brickCornerXPos(row,col)+brickWidth/2;
                    offy = brickCornerYPos(row,col)+brickDepth/2;
                elseif bricksStatus(horSect,vertSect) == Laser
                    delete(bricks(horSect,vertSect))
                    bricksStatus(horSect,vertSect) = 0;
                    lasergun_on = 1;
                elseif bricksStatus(horSect,vertSect) == Life
                    delete(bricks(horSect,vertSect))
                    bricksStatus(horSect,vertSect) = 0;
                    life_down = 1;
                elseif bricksStatus(horSect,vertSect) ~= 0
                    bricksStatus(horSect,vertSect) = 0;
                    delete(bricks(horSect,vertSect))
                end
                end
                %Get G_offx and G_offy
                G_offx = BallPos(1);
                G_offy = BallPos(2);
                %Animate
                [G_expl_p,G_in_expl_p] = A_animate_G_expl(G_expl_org,G_offx,G_offy);
            end
            if A > 1 && A < 11
                B_animate_G_expl(G_expl_p,G_in_expl_p,G_expl_org,A,G_offx,G_offy);
            end
            if A == 11
                [G_expl2_p] = C_animate_G_expl(G_expl2_org,G_offx,G_offy);
            end
            if A > 11 && A < 22
                D_animate_G_expl(G_expl2_p,G_expl2_org,A,G_offx,G_offy);
            end
            if A == 22
                [G_expl3a_p,G_expl3b_p,G_expl3c_p] = E_animate_G_expl(G_expl_p,G_in_expl_p,G_expl2_p,G_expl3a_org,G_expl3b_org,...
                G_expl3c_org,G_offx,G_offy);
            end
            if A > 22 && A < 34
                F_animate_G_expl(G_expl3a_p,G_expl3b_p,G_expl3c_p,G_expl3a_org,G_expl3b_org,...
                G_expl3c_org,A,G_offx,G_offy);
            end
            if A == 34
                G_animate_G_expl(G_expl3a_p,G_expl3b_p,G_expl3c_p);
            end 
            if A == 35
                G_exploding = 0; %reset G_exploding variable
                G_time = 0; %reset G_time variable
                A = 0; %reset A (iteration counter for explosion animations)
            end
    end
    
    %Update block's position
    if mode == auto
        BlockCenter = BallPos(1);
        set(Block,'XData',...
            [BlockCenter-bwidth/2,BlockCenter+bwidth/2]);
    elseif mode == mouse
        %Use function to update block position
        [BlockCenter,Block] = updateBlockPos(BlockCenter,bwidth,...
        pixperunit,Block,xMin,xMax,bThickness);
    elseif mode == keys
        %Allow keyboard function to update block position
        set(Block,'XData',...
            [BlockCenter-bwidth/2,BlockCenter+bwidth/2]);  
    end
    
    %Laser meter
    if lasergun_on == 1
        for n = 1:5
            lasermeter_p(n) = line([73+(n-1)*lasermeterdist,77.5+(n-1)*lasermeterdist],...
                [-12.5,-12.5],'linewidth',meterwidth,'color',blue);
        end
    end
    
    %Create lasergun patch and update it's position
    if lasergun_on == 1 %lasergun is on but patch doesn't exist yet
        %Create patch
        [lasergun_p,lasergun_xCoords,lasergun_yCoords] =...
            create_lasergun(BlockThickness,lightgray);
        %Update patch position
        set(lasergun_p,'XData',lasergun_xCoords+BlockCenter,...
                       'YData',lasergun_yCoords);     
        lasergun_on = 2; %change lasergun_on to show that patch exists
    elseif lasergun_on == 2 %patch is created and lasergun is on
        %Update patch position
        set(lasergun_p,'XData',lasergun_xCoords+BlockCenter,...
                       'YData',lasergun_yCoords);     
    end
    
    %Create heart patch for Life brick
    if life_down == 1
        life_down = 2; %reset life_down
        heartXPos = brickCornerXPos(rHeart,cHeart)+brickWidth/2;
        heartYPos = brickCornerYPos(rHeart,cHeart)+brickDepth/4;
        fallHeart_p = patch(heartX+heartXPos,heartY+heartYPos,pink);
    elseif life_down == 2
        %Update position of falling heart
        set(fallHeart_p,'XData',heartX+heartXPos,...
                        'YData',heartY+heartYPos+heartShift*H_time);
        if heartYPos+heartShift*H_time+2 <= 0 %heart is at bottom of screen
            delete(fallHeart_p)
            life_down = 0; %reset life_down
            if heartXPos > BlockCenter-bwidth/2 &&...
                heartXPos < BlockCenter+bwidth/2
                %Heart was "caught," award life
                lives = lives+1;
                hearts(lives) = patch(heartX+minX+2/3*bThickness+heartdist*(lives-1),heartY-15,pink);
            end
        end
    end
    
    %Speed change
    [BallVel,BallVel1_org] = speedChange(BallVel,numIT,p,BallVel1_org);
    
    %Update time and counter
    pause(p);
    t = t+p;
    numIT = numIT+1;
    if G_time > 0
    G_time = G_time+1; %update G_time
    end
    if L_time > 0
        L_time = L_time+1; %update L_time
    end
    if life_down == 2
        H_time = H_time+1; %update H_time
    end
    
    %Calculate "horizontal section" and "vertical section," using function
    [vertSect,horSect] = locateBall(BallPos,...
    numBricksAcross,numBricksDown,vertBricksLeft,brickCornerXPos,...
    brickCornerYPos,brickDepth,brickWidth,shift);
    %Calculate borders
    [minX,maxX,minY,maxY] = calcBorders(BallPos,numBricksAcross,...
    numBricksDown,brickWidth,brickDepth,bricksStatus,brickCornerXPos,...
    brickCornerYPos,maxY,vertSect,horSect,shift,G_time,max_G_time);
end %while stop ~= 1

stop = 0; %change stop

delete(Ball) %delete ball (maybe after animation)
%BALL DATA: Re-initialize 
%Direction signal variables
left = -1;
right = 1;
down = -1;
up = 1;
%Direction change signal variables
inY = 0;
inX = 1;
%Initial directions
xDirection = right;
yDirection = up;
%Ball velocity
BallVel = BallVel0;

if shiftDeath ~= 1 && lives > 1
%Reset powerups
%Boom
if B_exploding == 1
   %Delete animation patch(es)
    if N > 1 && N <= 11
        delete(expl_p)
        delete(in_expl_p)
    elseif N <= 22
        delete(expl_p)
        delete(in_expl_p)
        delete(expl2_p)
    elseif N < 34
        delete(expl3a_p)
        delete(expl3b_p)
        delete(expl3c_p)
    end
    N = 0; %reset N
    B_exploding = 0 %reset B_exploding
end
%Laser
if lasergun_on ~= 0
    for n = 1:shots_left
        delete(lasermeter_p(6-n))
    end
    lasergun_on = 0;
    shots_left = 5;
    delete(lasergun_p)
    if L_time > 2 && L_time < 11
        delete(laser_p)
    end
    L_time = 0;
end
%Ghost
if G_time ~= 0
    G_time = 0;
    delete(G_meter_p)
    if G_exploding == 1
    %Delete animation patch(es)
    if A > 1 && A <= 11
        delete(G_expl_p)
        delete(G_in_expl_p)
    elseif A <= 22
        delete(G_expl_p)
        delete(G_in_expl_p)
        delete(G_expl2_p)
    elseif A < 34
        delete(G_expl3a_p)
        delete(G_expl3b_p)
        delete(G_expl3c_p)
    end
    A = 0; %reset A
    G_exploding = 0 %reset G_exploding
    end
end
%Heart
if life_down == 2
    delete(fallHeart_p)
    life_down = 0;
end
end

pause(0.25)

%Lose heart animation
if shiftDeath ~= 1
for n = 1:10
    delete(hearts(lives))
    new_heartX = heartX*(11-n)/10;
    new_heartY = heartY*(11-n)/10;
    hearts(lives) = patch(new_heartX+2/3*bThickness+heartdist*(lives-1),...
                          new_heartY-15,pink);
    pause(p)
end
delete(hearts(lives)) %delete heart after animation
lives = lives-1; %decrease lives value
else %death is by shift, delete all remaining hearts
    for n = 1:10
        for H = 1:lives
        delete(hearts(H))
        new_heartX = heartX*(11-n)/10;
        new_heartY = heartY*(11-n)/10;
        hearts(H) = patch(new_heartX+2/3*bThickness+heartdist*(H-1),...
                              new_heartY-15,pink);
        end
        pause(p)
    end
    delete(hearts) %deletes all heart patches
    lives = 0;
    pause(0.5)
end

end %while lives > 0
GAMEOVER(white) %GAMEOVER animation
end %while playing == 1

%% FUNCTIONS

function [B1_p,R1_p,I_p,C_p,K1_p,B2_p,R2_p,E1_p,A_p,K2_p,E2_p,R3_p,tBall_p] = animatebricks
background
darkred = [0.9,0,0];
markersize = 70;
white = [1,1,1];
p = 0.015;
BallRad = markersize/35;

%Initial positions and velocities
num = 30; %num of iterations
tBallVel = [0.55,-1.1];
tBallAcl = [-tBallVel(1)/num,-tBallVel(2)/num];
tBallPos = [42.5,110];
NUM = 30; %NUM of iterations
BRICKPos = 0;
BRICKVel = -0.2;
BRICKAcl = -BRICKVel/NUM;
BREAKERPos = 0;
BREAKERVel = -0.4;
BREAKERAcl = -BREAKERVel/NUM;

%Create initial brick patches
tBrick1X = [10,90,90,10];
tBrick1Y = [65,65,95,95];
pause(0.5)
tBrick1_p = patch(tBrick1X,tBrick1Y,darkred);
tBrick2X = tBrick1X;
tBrick2Y = [35,35,65,65];
pause(0.5)
tBrick2_p = patch(tBrick2X,tBrick2Y,darkred);
%Create tBall patch
tBall_p =  line(tBallPos(1),tBallPos(2),'marker','.',...
   'markersize',markersize,'color',white);

%BRICK letter coords and patches
B1X = [10,10,30,30,27.5,30,30,16.5,16.5,23.5,23.5,16.5,16.5,23.5,23.5,16.5,16.5];
B1Y = [65,95,95,82.5,80,77.5,65,65,71,71,77,77,83,83,89,89,65];
R1X = [30,30,48,48,45,42,42,36,36,45,48,48,42,42,36,36];
R1Y = [65,95,95,86,82.5,82.5,89,89,82.5,82.5,79,65,65,75,75,65];
IX = [48,48,54,54];
IY = [65,92,92,65];
CX = [54,54,70,70,60,60,70,70];
CY = [65,95,95,87,87,73,73,65];
K1X = [70,70,76,76,83,89.87,80,89.87,83,76,76];
K1Y = [65,95,95,85,95,95,80,65,65,75,65];

%BREAKER letter coords and patches
for n = 1:17
    B2X(n) = 0.65*B1X(n)+3.5;
    B2Y(n) = B1Y(n)-30;
end
for n = 1:16
    R2X(n) = 0.7*R1X(n)+2;
    R2Y(n) = R1Y(n)-30;
end
E1X = [35.6,35.6,45,45,40,40,45,45,40,40,45,45];
E1Y = [35,65,65,59,59,53,53,47,47,41,41,35];
AX = 1.15*[45,45,55,55,51.3,51.3,48,48,51.3,51.3,48,48];
AY = [35,65,65,35,35,43,43,51,51,59,59,35];
for n = 1:12
   AX(n) = AX(n)-6.75; 
end
for n = 1:11
    K2X(n) = 0.6*K1X(n)+14.5;
    K2Y(n) = K1Y(n)-30;
end
for n = 1:12
    E2X(n) = E1X(n)+32.9;
    E2Y(n) = E1Y(n);
end
for n = 1:16
   R3X(n) = 0.95*R2X(n)+56.05;
   R3Y(n) = R2Y(n);
end
pause(0.5)
for n = 1:100
    %tBall motion
    if n <= num
    %negate y-vel is tBall hits top of tBrick
    if tBallPos(2) - BallRad <= 95
        tBallVel(2) = -tBallVel(2);
        tBallAcl(2) = -tBallAcl(2);
        %(ball switches direction on n = 17)
    end
    %move tBall
    set(tBall_p,'XData',tBallPos(1)+tBallVel(1),...
                'YData',tBallPos(2)+tBallVel(2));
    %update tBallPos
    tBallPos = [tBallPos(1)+tBallVel(1),...
                tBallPos(2)+tBallVel(2)];
    %update tBallVel
    tBallVel = [tBallVel(1)+tBallAcl(1),tBallVel(2)+tBallAcl(2)];
    end
    
    %tBrick motion
    if n == 17
        %replace bricks with letters
        delete(tBrick1_p)
        delete(tBrick2_p)
        %BRICK letters
        B1_p = patch(B1X,B1Y,darkred);
        R1_p = patch(R1X,R1Y,darkred);
        I_p = patch(IX,IY,darkred);
        C_p = patch(CX,CY,darkred);
        K1_p = patch(K1X,K1Y,darkred);
        %BREAKER letters
        B2_p = patch(B2X,B2Y,darkred);
        R2_p = patch(R2X,R2Y,darkred);
        E1_p = patch(E1X,E1Y,darkred);
        A_p = patch(AX,AY,darkred);
        K2_p = patch(K2X,K2Y,darkred);
        E2_p = patch(E2X,E2Y,darkred);
        R3_p = patch(R3X,R3Y,darkred);
    end
    
    %Shift letters down
    if n > 17 && n < 17+NUM
        %Shift BRICK
        set(B1_p,'XData',B1X,'YData',B1Y+BRICKPos);
        set(R1_p,'XData',R1X,'YData',R1Y+BRICKPos);
        set(I_p,'XData',IX,'YData',IY+BRICKPos);
        set(C_p,'XData',CX,'YData',CY+BRICKPos);
        set(K1_p,'XData',K1X,'YData',K1Y+BRICKPos);
        %Shift BREAKER
        set(B2_p,'XData',B2X,'YData',B2Y+BREAKERPos);
        set(R2_p,'XData',R2X,'YData',R2Y+BREAKERPos);
        set(E1_p,'XData',E1X,'YData',E1Y+BREAKERPos);
        set(A_p,'XData',AX,'YData',AY+BREAKERPos);
        set(K2_p,'XData',K2X,'YData',K2Y+BREAKERPos);
        set(E2_p,'XData',E2X,'YData',E2Y+BREAKERPos);
        set(R3_p,'XData',R3X,'YData',R3Y+BREAKERPos);
        %Update positions and velocities
        BRICKPos = BRICKPos+BRICKVel;
        BRICKVel = BRICKVel+BRICKAcl;
        BREAKERPos = BREAKERPos+BREAKERVel;
        BREAKERVel = BREAKERVel+BREAKERAcl;
    end
    
    pause(p)
end
function background
%Get screensize
screensize = get(0,'ScreenSize');
figwidth = screensize(3)/2;
figheight = screensize(4)-120;

%Create blue figure that has a KeyPressFcn with a function handle
%keyboardFunction
brickwallsFigure = figure('Position',[0,40,figwidth,figheight],...
    'color','blue','KeyPressFcn',@keyboardFunction);

%Ratios of axes positions to fig window positions
xMinAxesRat = 0;
xMaxAxesRat = 1;
yMinAxesRat = 0;
yMaxAxesRat = 1;
%Axes mins and maxes
xMin = -5;
xMax = 105;
yMin = -20;
yMax = 105;
%Create axes
brickwallsAxes = axes('XLim',[xMin xMax],'YLim',[yMin yMax],...
    'color','black',...
    'XTickLabels',[],'YTickLabels',[],...
    'position',[xMinAxesRat,yMinAxesRat,xMaxAxesRat,yMaxAxesRat]);
grid on
end
end

function keyboardFunction(figure,event)
global BlockCenter dBlockCenter bwidth G_time max_G_time lasergun_on L_time
switch event.Key
    case 'leftarrow'
        if BlockCenter-bwidth/2 > 0 %left end is greater than zero
            if BlockCenter-bwidth/2-dBlockCenter > 0 %new left end is also
                %greater than zero
                BlockCenter = BlockCenter-dBlockCenter;
            else
                BlockCenter = 0+bwidth/2; %new left end becomes 0
            end
        end
    case 'rightarrow'
        if BlockCenter+bwidth/2 < 100 %right end is less than 100
            if BlockCenter+bwidth/2+dBlockCenter < 100 %new right end
                %is also less than 100
                BlockCenter = BlockCenter+dBlockCenter;
            else
                BlockCenter = 100-bwidth/2; %new right end becomes 100
            end
        end
    case 'space'
        if G_time ~= 0 && G_time < max_G_time-1 %Ghost power up is active
        G_time = max_G_time-1; %activates explosion
        elseif lasergun_on == 2 && L_time == 0 %lasergun power up is active
            L_time = 1;
        end
end
end

function [BlockCenter,Block] = updateBlockPos(BlockCenter,bwidth,...
    pixperunit,Block,xMin,xMax,bThickness)
%Block Position
mousePos = get(0,'PointerLocation'); %gets pointer coordinates in pixels
mouseXPos = mousePos(1); %x coordinate of pointer
PosInUnits = mouseXPos/pixperunit+xMin; %Convert to graph units
if PosInUnits > xMin+bThickness+bwidth/2+0.9 &&...
   PosInUnits < xMax-bThickness-bwidth/2-0.9 %mouse in between
    %upper and lower x limits
    %Update block position
    BlockCenter = PosInUnits;
    set(Block,'XData',...
        [BlockCenter-1.1*bwidth/2,BlockCenter+1.1*bwidth/2]);
end
end

function [vertSect,horSect] = locateBall(BallPos,...
    numBricksAcross,numBricksDown,vertBricksLeft,brickCornerXPos,...
    brickCornerYPos,brickDepth,brickWidth,shift)

%Calculate "vertical section" of ball (x-position)
for n = 1:numBricksAcross
    x = BallPos(1) - brickCornerXPos(1,n);
    if x < brickWidth && x >= 0
        vertSect = n;
    end
end

%Calculate "horizontal section" of ball (y-position)
if BallPos(2) <= 100-(numBricksDown*brickDepth+abs(shift))
    horSect = numBricksDown+1; %represents condition of ball being below
                               %bricks
elseif BallPos(2) > 100+shift %ball is above bricks
    horSect = 0; %represents condition of ball being above bricks
else %ball is within bricks
    for n = 1:numBricksDown
        x = BallPos(2) - (brickCornerYPos(n,1)); %do not include shift in
        %this equation! the brickCornerYPos is updated along with shift so
        %it already includes the changes
        if x < brickDepth && x > 0
            horSect = n;
        end
    end
end
end

function [minX,maxX,minY,maxY] = calcBorders(BallPos,numBricksAcross,...
    numBricksDown,brickWidth,brickDepth,bricksStatus,brickCornerXPos,...
    brickCornerYPos,maxY,vertSect,horSect,shift,G_time,max_G_time)
%These are the values for below the bricks and they don't matter for above
%the bricks, but need to be here so they can be "outputted."
%Also, they are always the limits when Ghost Ball is activated.

%Calc minX
minX = 0;
%Calc maxX
maxX = 100;
%Calc minY
minY = 0;
%Calc maxY
maxY = 100; %in case there are no bricks on the lowest level to start
if G_time == 0 || G_time > max_G_time
if horSect == numBricksDown+1 %Ball is below bricks
    %Calc maxY
    for n = 1:numBricksDown
        if bricksStatus(n,vertSect) ~= 0
           maxY = 100-n*brickDepth+shift;
        end
    end
elseif horSect == 0 %ball is above bricks
    minX = 0;
    maxX = 100;
    %Check border brick (brick below ball)
    if bricksStatus(horSect+1,vertSect) ~= 0
        minY = brickCornerYPos(horSect+1,vertSect)+brickDepth;
    else
        minY = 0;
    end
    maxY = 100;
else %ball is within bricks
    if vertSect == 1 && horSect == 1 %ball is in top-left corner of brick
                                     %grid
        %check border bricks
        %right side (maxX)
        if bricksStatus(horSect,vertSect+1) ~= 0
            maxX = brickCornerXPos(horSect,vertSect+1);
        else
            maxX = 100;
        end
        %bottom side (minY)
        if bricksStatus(horSect+1,vertSect) ~= 0
            minY = brickDepth+brickCornerYPos(horSect+1,vertSect);
        else
            minY = 0;
        end
    elseif vertSect == 1 && horSect == numBricksDown %ball is in
                                     %bottom-left corner of brick grid
        %check border bricks
        %right side (maxX)
        if bricksStatus(horSect,vertSect+1) ~= 0
            maxX = brickCornerXPos(horSect,vertSect+1);
        else
            maxX = 100;
        end
        %top side (maxY)
        if bricksStatus(horSect-1,vertSect) ~= 0
            maxY = brickCornerYPos(horSect-1,vertSect);
        else
            maxY = 100;
        end
    elseif vertSect == numBricksAcross && horSect == 1 %ball is in
                                     %top-right corner of brick grid
        %check border bricks
        %left side (minX)
        if bricksStatus(horSect,vertSect-1) ~= 0
            minX = brickWidth+brickCornerXPos(horSect,vertSect-1);
        else
            minX = 0;
        end
        %bottom side (minY)
        if bricksStatus(horSect+1,vertSect) ~= 0
            minY = brickDepth+brickCornerYPos(horSect+1,vertSect);
        else
            minY = 0;
        end
    elseif vertSect == numBricksAcross && horSect == numBricksDown %ball is
                                    %in bottom-right corner of brick grid
        %check border bricks
        %left side (minX)
        if bricksStatus(horSect,vertSect-1) ~= 0
            minX = brickWidth+brickCornerXPos(horSect,vertSect-1);
        else
            minX = 0;
        end
        %top side (maxY)
        if bricksStatus(horSect-1,vertSect) ~= 0
            maxY = brickCornerYPos(horSect-1,vertSect);
        else
            maxY = 100;
        end
    elseif vertSect == 1 %ball is in leftmost "vertical section"
        %check border bricks
        %right side (maxX)
        if bricksStatus(horSect,vertSect+1) ~= 0
            maxX = brickCornerXPos(horSect,vertSect+1);
        else
            maxX = 100;
        end
        %bottom side (minY)
        if bricksStatus(horSect+1,vertSect) ~= 0
            minY = brickDepth+brickCornerYPos(horSect+1,vertSect);
        else
            minY = 0;
        end
        %top side (maxY)
        if bricksStatus(horSect-1,vertSect) ~= 0
            maxY = brickCornerYPos(horSect-1,vertSect);
        else
            maxY = 100;
        end
    elseif vertSect == numBricksAcross %ball is in rightmost "vertical
                                       %section"
        %check border bricks
        %left side (minX)
        if bricksStatus(horSect,vertSect-1) ~= 0
            minX = brickWidth+brickCornerXPos(horSect,vertSect-1);
        else
            minX = 0;
        end
        %bottom side (minY)
        if bricksStatus(horSect+1,vertSect) ~= 0
            minY = brickDepth+brickCornerYPos(horSect+1,vertSect);
        else
            minY = 0;
        end
        %top side (maxY)
        if bricksStatus(horSect-1,vertSect) ~= 0
            maxY = brickCornerYPos(horSect-1,vertSect);
        else
            maxY = 100;
        end
    elseif horSect == 1 %ball is in topmost "horizontal section"
        %check border bricks
        %left side (minX)
        if bricksStatus(horSect,vertSect-1) ~= 0
            minX = brickWidth+brickCornerXPos(horSect,vertSect-1);
        else
            minX = 0;
        end
        %right side (maxX)
        if bricksStatus(horSect,vertSect+1) ~= 0
            maxX = brickCornerXPos(horSect,vertSect+1);
        else
            maxX = 100;
        end
        %bottom side (minY)
        if bricksStatus(horSect+1,vertSect) ~= 0
            minY = brickDepth+brickCornerYPos(horSect+1,vertSect);
        else
            minY = 0;
        end
    elseif horSect == numBricksDown %ball is in bottommost "horiontal
                                    %section"
        %check border bricks
        %left side (minX)
        if bricksStatus(horSect,vertSect-1) ~= 0
            minX = brickWidth+brickCornerXPos(horSect,vertSect-1);
        else
            minX = 0;
        end
        %right side (maxX)
        if bricksStatus(horSect,vertSect+1) ~= 0
            maxX = brickCornerXPos(horSect,vertSect+1);
        else
            maxX = 100;
        end
        %top side (maxY)
        if bricksStatus(horSect-1,vertSect) ~= 0
            maxY = brickCornerYPos(horSect-1,vertSect);
        else
            maxY = 100;
        end
    else %ball is in middle section of bricks
    %Check border bricks
        %left side (minX)
        if bricksStatus(horSect,vertSect-1) ~= 0
            minX = brickWidth+brickCornerXPos(horSect,vertSect-1);
        else
            minX = 0;
        end
        %right side (maxX)
        if bricksStatus(horSect,vertSect+1) ~= 0
            maxX = brickCornerXPos(horSect,vertSect+1);
        else
            maxX = 100;
        end
        %bottom side (minY)
        if bricksStatus(horSect+1,vertSect) ~= 0
            minY = brickDepth+brickCornerYPos(horSect+1,vertSect);
        else
            minY = 0;
        end
        %top side (maxY)
        if bricksStatus(horSect-1,vertSect) ~= 0
            maxY = brickCornerYPos(horSect-1,vertSect);
        else
            maxY = 100;
        end
    end
end
end %if G_time > 0 && G_time < max_G_time
end

function [BallVel,xDirection] = calc_xVel(BallVel1_org,BallVel,BallPos,...
    BlockCenter,bwidth,right,left)
x = BallPos(1)-BlockCenter;
%Determine section of block ball landed on and set constant value
if x < -3/10*bwidth
    constant = -1.15;
    xDirection = left;
elseif x < -1/10*bwidth
    constant = -1;
    xDirection = left;
elseif x < 0
    constant = -0.85;
    xDirection = left;
elseif x < 1/10*bwidth
    constant = 0.85;
    xDirection = right;
elseif x < 3/10*bwidth
    constant = 1;
    xDirection = right;
elseif x > 3/10*bwidth
    constant = 1.15;
    xDirection = right;
end
%Change velocity using new constant
BallVel(1) = BallVel1_org*constant;
end

function [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left] = brickReact(numBricksDown,...
        horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
        StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
        crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
        up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
        Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
        BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left)
%In the animation part of this function, the r and c usually used for row
%and column values are called row and col (r already exists in the
%animation functions)

if horSect == numBricksDown+1 %ball is below bricks
    r = numBricksDown;
    c = vertSect;
elseif horSect == 0 %ball is above bricks
    r = 1;
    c = vertSect;
else %ball is within bricks
    if change == inY
        c = vertSect;
        if yDirection == up %ball is moving up
            r = horSect-1;
        elseif yDirection == down %ball is moving down
            r = horSect+1;
        end
    elseif change == inX
        r = horSect;
        if xDirection == right %ball is moving right
            c = vertSect+1;
        elseif xDirection == left %ball is moving left
            c = vertSect-1;
        end
    end
end
    %Brick Reaction
    if bricksStatus(r,c) == Basic ||...
       bricksStatus(r,c) == StrongCracked
        %Delete brick
        bricksStatus(r,c) = 0;
        delete(bricks(r,c));
    elseif bricksStatus(r,c) == Strong
        %Crack brick and change brick type
        delete(bricks(r,c))
        bricks(r,c) = patch(crackedbrickXCoords...
            +brickCornerXPos(r,c),...
            crackedbrickYCoords+brickCornerYPos(r,c),StrongBrickColor);
            bricksStatus(r,c) = StrongCracked;
    elseif bricksStatus(r,c) == Steel
        %Ball bounces off brick, brick is unchanged
    elseif bricksStatus(r,c) == Boom
        %Brick explodes and destroys all bordering bricks that exist
        %Check for existence **only works if brick is not on edge
        for R = r-1:r+1
            for C = c-1:c+1
                if bricksStatus(R,C) ~= 0
                    bricksStatus(R,C) = 0;
                    delete(bricks(R,C))
                end
            end
        end
        %Change B_exploding variable
        B_exploding = 1;
        %Rename r and c
        row = r;
        col = c;
        %Define shifts
        offx = brickCornerXPos(row,col)+brickWidth/2;
        offy = brickCornerYPos(row,col)+brickDepth/2;
    elseif bricksStatus(r,c) == Ghost
        if lasergun_on ~= 0
            old_shots_left = shots_left;
            shots_left = 0;
        end
        offx = BallPos(1);
        offy = BallPos(2);
        delete(bricks(r,c))
        bricksStatus(r,c) = 0;
        G_time = 1;
    elseif bricksStatus(r,c) == Laser
        delete(bricks(r,c))
        bricksStatus(r,c) = 0;
        lasergun_on = 1;
    elseif bricksStatus(r,c) == Life
        delete(bricks(r,c))
        bricksStatus(r,c) = 0;
        life_down = 1;
    end
%Placeholder outputs incase nothing is changed
bricksStatus;
bricks;
B_exploding;
offx;
offy;
G_time;
lasergun_on;
shots_left;
life_down;
old_shots_left;
end

function [bricks,brickCornerYPos,shift,stop,shiftDeath] = shiftBricks(numBricksDown,...
            numBricksAcross,brickCornerYPos_org,bricksStatus,Basic,...
            Strong,Boom,Steel,brickXCoords,brickYCoords,brickCornerXPos,...
            brickCornerYPos,crackedbrickXCoords,crackedbrickYCoords,...
            shift,bricks,StrongCracked,dshift,stop,BlockThickness,Ghost,...
            Laser,Life,shiftDeath)
shift = shift+dshift; %change shift
for r = 1:numBricksDown
    for c = 1:numBricksAcross
        brickCornerYPos(r,c) = brickCornerYPos_org(r,c)+shift; %Update coords
        if bricksStatus(r,c) ~= 0
            if bricksStatus(r,c) == Basic ||...
               bricksStatus(r,c) == Strong ||...
               bricksStatus(r,c) == Steel ||...
               bricksStatus(r,c) == Boom ||...
               bricksStatus(r,c) == Ghost ||...
               bricksStatus(r,c) == Laser ||...
               bricksStatus(r,c) == Life
                set(bricks(r,c),'XData',brickXCoords+...
                brickCornerXPos(r,c),'YData',brickYCoords+...
                brickCornerYPos(r,c))
            elseif bricksStatus(r,c) == StrongCracked
                set(bricks(r,c),'XData',crackedbrickXCoords+...
                brickCornerXPos(r,c),'YData',...
                crackedbrickYCoords+brickCornerYPos(r,c))  
            end
        end
    end
end

%Check if bricks have shifted too low
if brickCornerYPos(numBricksDown,1) <= 0+BlockThickness
    stop = 1; %change stop
    shiftDeath = 1; %change shiftDeath
else
    stop; %stop remains unchanged
    shiftDeath; %shiftDeath remains unchanged
end

end

%Does not work once all bricks are destroyed, can make a condition to
%prevent this issue, have to see if it's worth it/how "winning" is going to
%work
function [numBricksDown] = update_numBricksDown(numBricksDown,...
    numBricksAcross,bricksStatus)
ok = 1;
existence = 0; %represents whether brick exists
n = 0; %counter
for n = 1:numBricksAcross
    if bricksStatus(numBricksDown,n) ~= 0
        ok = 0;
    end
end
%Check to see how many bricks on bottom row do not exist
if ok == 1
    numBricksDown = numBricksDown-1; %update numBricksDown
end
end

function [BallVel,BallVel1_org] = speedChange(BallVel,numIT,p,BallVel1_org)
n = numIT;  
dBallVel = 0.05;
%Increase speed incrementally for difficulty (every 7.5 secs)
    if n == 7.5/p || n == 15/p || n == 22.5/p || n == 30/p ||...
       n == 37.5/p || n == 45/p || n == 52.5/p || n == 60/p ||...
       n == 67.5/p || n == 75/p
        if BallVel(1) > 0
            BallVel1_org = BallVel1_org+dBallVel;
        else
            BallVel1_org = BallVel1_org-dBallVel;
        end
        if BallVel(2) > 0
            BallVel(2) = BallVel(2)+dBallVel;
        else
            BallVel(2) = BallVel(2)-dBallVel;
        end
    end
BallVel;
end

function countdown(white)
scale = 3;
xShift = 50;
yShift = 50;
pause(0.5) %before animation starts (looks good like this)
%Three
threeX = scale*[2,-2,-2,0,0,-2,-2,0,0,-2,-2,2];
threeY = scale*[5,5,3,3,1,1,-1,-1,-3,-3,-5,-5];
three_p = patch(threeX+xShift,threeY+yShift,white);
pause(1)
delete(three_p)
%Two
twoX = scale*[2,-2,-2,0,0,-2,-2,2,2,0,0,2];
twoY = scale*[5,5,3,3,1,1,-5,-5,-3,-3,-1,-1];
two_p = patch(twoX+xShift,twoY+yShift,white);
pause(1)
delete(two_p)
%One
oneX = scale*[1,-1,-1,1];
oneY = scale*[5,5,-5,-5];
one_p = patch(oneX+xShift,oneY+yShift,white);
pause(1)
delete(one_p)
end

function GAMEOVER(white)
scale = 4;
%Coords
G_X = scale*[-7,-7,-4,-4,-6,-6,-5,-5,-5.5,-5.5,-4,-4];
G_Y = scale*[0,5,5,4,4,1,1,2,2,3,3,0];
A_X = scale*[-3,-3,0,0,-1,-1,-2,-2,-1,-1,-2,-2];
A_Y = scale*[0,5,5,0,0,2,2,3,3,4,4,0];
M_X = scale*[1,1,2,2.5,3,4,4,3,3,2.5,2,2];
M_Y = scale*[0,5,5,4,5,5,0,0,3,2,3,0];
E1_X = scale*[5,5,8,8,6,6,8,8,6,6,8,8];
E1_Y = scale*[0,5,5,4,4,3,3,2,2,1,1,0];

O_X = scale*[-7,-7,-4,-4,-6,-6,-5,-5,-6,-6];
O_Y = scale*[-5,0,0,-5,-5,-4,-4,-1,-1,-5];
V_X = scale*[-3,-2,-1.5,-1,0,-1,-2];
V_Y = scale*[0,0,-3,0,0,-5,-5];
E2_X = scale*[1,1,4,4,2,2,4,4,2,2,4,4];
E2_Y = scale*[-5,0,0,-1,-1,-2,-2,-3,-3,-4,-4,-5];
R_X = scale*[5,5,8,8,7.5,7,7,6,6,7.5,8,8,7,7,6,6];
R_Y = scale*[-5,0,0,-1.5,-2,-2,-1,-1,-2,-2,-2.5,-5,-5,-3,-3,-5];

%Patches
pause(0.5)
G__p = patch(G_X+50-0.5*scale,G_Y+50+0.5*scale,white);
A__p = patch(A_X+50-0.5*scale,A_Y+50+0.5*scale,white);
M__p = patch(M_X+50-0.5*scale,M_Y+50+0.5*scale,white);
E1__p = patch(E1_X+50-0.5*scale,E1_Y+50+0.5*scale,white);
pause(0.5)
O__p = patch(O_X+50-0.5*scale,O_Y+50-0.5*scale,white);
V__p = patch(V_X+50-0.5*scale,V_Y+50-0.5*scale,white);
E2__p = patch(E2_X+50-0.5*scale,E2_Y+50-0.5*scale,white);
R__p = patch(R_X+50-0.5*scale,R_Y+50-0.5*scale,white);
end

%% POWER UP FUNCTIONS

%BOOM EXPLOSION ANIMATION
%Initial patch
function [expl_p,in_expl_p] = A_animate_B_expl(expl_org,offx,offy)
%Create initial patch for expl and in_expl (inner explosion)
expl_p = patch(1/10*expl_org(1,:)+offx,...
               1/10*expl_org(2,:)+offy,'y');
in_expl_p = patch(3/40*expl_org(1,:)+offx,...
                  3/40*expl_org(2,:)+offy,'r');
end
%Move
function B_animate_B_expl(expl_p,in_expl_p,expl_org,N,offx,offy)
%Make it expand
expl = expl_org*N;
in_expl = expl_org*N*3/4;
set(expl_p,'XData',expl(1,:)+offx,'YData',expl(2,:)+offy);
set(in_expl_p,'XData',in_expl(1,:)+offx,'YData',in_expl(2,:)+offy);
end
%Initial Patch
function [expl2_p] = C_animate_B_expl(expl2_org,offx,offy)
expl2_p = patch(1/10*expl2_org(1,:)+offx,1/10*expl2_org(2,:)+offy,'k');
end
%Move
function D_animate_B_expl(expl2_p,expl2_org,N,offx,offy)
expl2 = expl2_org*(N-10)/10;
set(expl2_p,'XData',expl2(1,:)+offx,'YData',expl2(2,:)+offy);
end
%Initial Patch
function [expl3a_p,expl3b_p,expl3c_p] = E_animate_B_expl(expl_p,in_expl_p,expl2_p,expl3a_org,expl3b_org,...
    expl3c_org,offx,offy)
%Delete patches of expl, expl_in, and expl2
delete(expl_p)
delete(in_expl_p)
delete(expl2_p)
%Create initial patch for expl3
expl3a_p = patch(expl3a_org(1,:)-8+offx,expl3a_org(2,:)-4+offy,'y');
expl3b_p = patch(expl3b_org(1,:)+0+offx,expl3b_org(2,:)+6+offy,'y');
expl3c_p = patch(expl3c_org(1,:)+7+offx,expl3c_org(2,:)-3+offy,'y');
end
%Move
function F_animate_B_expl(expl3a_p,expl3b_p,expl3c_p,expl3a_org,expl3b_org,...
    expl3c_org,N,offx,offy)
%Shrink expl3 patches
%Exponential rate decrease
expl3a = expl3a_org*(34-N)/11;
expl3b = expl3b_org*(34-N)/11;
expl3c = expl3c_org*(34-N)/11;
set(expl3a_p,'XData',expl3a(1,:)-8+offx,'YData',expl3a(2,:)-4+offy);
set(expl3b_p,'XData',expl3b(1,:)+0+offx,'YData',expl3b(2,:)+6+offy);
set(expl3c_p,'XData',expl3c(1,:)+7+offx,'YData',expl3c(2,:)-3+offy);
end
%Done
function G_animate_B_expl(expl3a_p,expl3b_p,expl3c_p)
%Delete patches of expl3
delete(expl3a_p)
delete(expl3b_p)
delete(expl3c_p)
end

%GHOST EXPLOSION ANIMATION
%Initial patch
function [G_expl_p,G_in_expl_p] = A_animate_G_expl(G_expl_org,G_offx,G_offy)
%Create initial patch for expl and in_expl (inner explosion)
G_expl_p = patch(1/10*G_expl_org(1,:)+G_offx,...
               1/10*G_expl_org(2,:)+G_offy,'w');
G_in_expl_p = patch(3/40*G_expl_org(1,:)+G_offx,...
                  3/40*G_expl_org(2,:)+G_offy,'b');
end
%Move
function B_animate_G_expl(G_expl_p,G_in_expl_p,G_expl_org,A,G_offx,G_offy)
%Make it expand
G_expl = G_expl_org*A;
G_in_expl = G_expl_org*A*3/4;
set(G_expl_p,'XData',G_expl(1,:)+G_offx,'YData',G_expl(2,:)+G_offy);
set(G_in_expl_p,'XData',G_in_expl(1,:)+G_offx,'YData',G_in_expl(2,:)+G_offy);
end
%Initial Patch
function [G_expl2_p] = C_animate_G_expl(G_expl2_org,G_offx,G_offy)
G_expl2_p = patch(1/10*G_expl2_org(1,:)+G_offx,1/10*G_expl2_org(2,:)+G_offy,'k');
end
%Move
function D_animate_G_expl(G_expl2_p,G_expl2_org,A,G_offx,G_offy)
G_expl2 = G_expl2_org*(A-10)/10;
set(G_expl2_p,'XData',G_expl2(1,:)+G_offx,'YData',G_expl2(2,:)+G_offy);
end
%Initial Patch
function [G_expl3a_p,G_expl3b_p,G_expl3c_p] = E_animate_G_expl(G_expl_p,G_in_expl_p,G_expl2_p,G_expl3a_org,G_expl3b_org,...
    G_expl3c_org,G_offx,G_offy)
%Delete patches of expl, expl_in, and expl2
delete(G_expl_p)
delete(G_in_expl_p)
delete(G_expl2_p)
%Create initial patch for expl3
G_expl3a_p = patch(G_expl3a_org(1,:)-4+G_offx,G_expl3a_org(2,:)-1+G_offy,'w');
G_expl3b_p = patch(G_expl3b_org(1,:)+0+G_offx,G_expl3b_org(2,:)+5+G_offy,'w');
G_expl3c_p = patch(G_expl3c_org(1,:)+3+G_offx,G_expl3c_org(2,:)+0+G_offy,'w');
end
%Move
function F_animate_G_expl(G_expl3a_p,G_expl3b_p,G_expl3c_p,G_expl3a_org,G_expl3b_org,...
    G_expl3c_org,A,G_offx,G_offy)
%Shrink expl3 patches
%Exponential rate decrease
G_expl3a = G_expl3a_org*(34-A)/11;
G_expl3b = G_expl3b_org*(34-A)/11;
G_expl3c = G_expl3c_org*(34-A)/11;
set(G_expl3a_p,'XData',G_expl3a(1,:)-4+G_offx,'YData',G_expl3a(2,:)-1+G_offy);
set(G_expl3b_p,'XData',G_expl3b(1,:)+0+G_offx,'YData',G_expl3b(2,:)+5+G_offy);
set(G_expl3c_p,'XData',G_expl3c(1,:)+3+G_offx,'YData',G_expl3c(2,:)+0+G_offy);
end
%Done
function G_animate_G_expl(G_expl3a_p,G_expl3b_p,G_expl3c_p)
%Delete patches of expl3
delete(G_expl3a_p)
delete(G_expl3b_p)
delete(G_expl3c_p)
end

%EXPLOSION COORDINATES
%B_explosion
function [expl_org] = create_expl
%Initial coords of curves (relative to center)
x1 = [ 3, 0,-2,-4,-3, 2, 2, 4]; %initial x
y1 = [-3,-4,-4, 1, 3, 5, 2, 0]; %initial y

%Offset values of curve centers
offx_arr = [ 0,-3,-5,-3, 1, 2, 5, 3];
offy_arr = [-4,-3, 1, 4, 5, 3,-1,-3];

%min and max values of theta
thmin_arr = [ -45,270,180+atan2d(4,2),180-atan2d(1,4),...
     135,90-atan2d(2,5), 45,  0];
thmax_arr = [-135,180,180-atan2d(4,2), 90-atan2d(1,4),...
      45,  -atan2d(2,5),-45,-90];

%Initialize nmin and nmax
nmin = -10;
nmax = 0;
for a = 1:8
%Calculate radius, angles, and offset values
r = sqrt(y1(a)^2+x1(a)^2);
thmin = thmin_arr(a);
thmax = thmax_arr(a);
dth = (thmax-thmin)/10;
offx = offx_arr(a);
offy = offy_arr(a);
nmin = nmin+11;
nmax = nmax+11;
    for n = nmin:nmax
        th(n) = thmin+dth*(n-(11*(a-1)+1));
        expl_x(n) = r*cosd(th(n))+offx;
        expl_y(n) = r*sind(th(n))+offy;
    end
end
%Concatenate x and y coords
expl_org = 12/100*[expl_x;expl_y];
end
function [expl2_org] = create_expl2
%Create coords of expl2
%Initial coords of curves (relative to center)
x1 = [ 3,2, 1/2,-1,-3,-1,-1/2]; %initial x
y1 = [ 1,0,-5/2,-3, 0, 2, 5/2]; %initial y

%Offset values of curve centers
offx_arr = [-2,-5,-11/2,-2,4, 5, 7/2];
offy_arr = [-6,-3,  3/2, 5,4,-1,-9/2];

%min and max values of theta
thmin_arr = [   atand(1/3), 0,-90+atand(1/5),-90-atand(1/3),...
    -180, 90+atand(1/2), 90+atand(1/5)];
thmax_arr = [90+atand(1/3),90,    atand(1/5),   -atand(1/3),...
     -90,180+atand(1/2),180+atand(1/5)];

%Initialize nmin and nmax
nmin = -10;
nmax = 0;
for a = 1:7
%Calculate radius, angles, and offset values
r = sqrt(y1(a)^2+x1(a)^2);
thmin = thmin_arr(a);
thmax = thmax_arr(a);
dth = (thmax-thmin)/10;
offx = offx_arr(a);
offy = offy_arr(a);
nmin = nmin+11;
nmax = nmax+11;
    for n = nmin:nmax
        th(n) = thmin+dth*(n-(11*(a-1)+1));
        expl_x2(n) = r*cosd(th(n))+offx;
        expl_y2(n) = r*sind(th(n))+offy;
    end
end
%Concatenate x and y coords
expl2_org = 12/10*[expl_x2;expl_y2];
end
function [expl3a_org,expl3b_org,expl3c_org] = create_expl3
[expl3a_org] = create_expl3a;
[expl3b_org] = create_expl3b;
[expl3c_org] = create_expl3c;

    function [expl3a_org] = create_expl3a %done
    %Initial coords of curves (relative to center)
    x1 = [-1, 1,-1, 1]; %initial x
    y1 = [ 2,-2,-2, 2]; %initial y
    
    %Offset values of curve centers
    offx_arr = [ 3, 0, 0, 0]; %[-2,-5,-5,-5];
    offy_arr = [-3, 0, 4, 0]; %[-6,-3, 1,-3];
    
    %min and max values of theta
    thmin_arr = [  90+atand(1/2), -90+atand(1/2),270-atand(1/2),...
        90-atand(1/2),90-atand(1/2)];
    thmax_arr = [-180-atand(1/2),-270+atand(1/2),-90+atand(1/2),...
          -atand(1/2),  -atand(1/2)];
    
    %Initialize nmin and nmax
    nmin = -20;
    nmax = 0;
    for a = 1:4
    %Calculate radius, angles, and offset values
    r = sqrt(y1(a)^2+x1(a)^2);
    thmin = thmin_arr(a);%atand(abs(y1(a)/x1(a)))+thmin_off;
    thmax = thmax_arr(a);%atand(abs(y2(a)/x2(a)))+thmax_off;
    dth = (thmax-thmin)/20;
    offx = offx_arr(a);
    offy = offy_arr(a);
    nmin = nmin+21;
    nmax = nmax+21;
        for n = nmin:nmax
            th(n) = thmin+dth*(n-(21*(a-1)+1));
            expl3a_x(n) = r*cosd(th(n))+offx;
            expl3a_y(n) = r*sind(th(n))+offy;
        end
    end
    %Concatenate x and y coords
    expl3a_org = [expl3a_x;expl3a_y];
    end
    function [expl3b_org] = create_expl3b
    %Initial coords of curves (relative to center)
    x1 = [ 1,-1,-1,-2]; %initial x
    y1 = [-2, 2, 1,-1]; %initial y
    
    %Offset values of curve centers
    offx_arr = [-3, 0, 3, 0];
    offy_arr = [ 1, 0, 0, 0];
    
    %min and max values of theta
    thmin_arr = [270+atand(1/2),90+atand(1/2), 90+atand(1/2),...
        -atand(1/2)];
    thmax_arr = [    atand(1/2),   atand(1/2),-90-atand(1/2),...
        -180+atand(1/2)];
    
    %Initialize nmin and nmax
    nmin = -20;
    nmax = 0;
    for a = 1:4
    %Calculate radius, angles, and offset values
    r = sqrt(y1(a)^2+x1(a)^2);
    thmin = thmin_arr(a);%atand(abs(y1(a)/x1(a)))+thmin_off;
    thmax = thmax_arr(a);%atand(abs(y2(a)/x2(a)))+thmax_off;
    dth = (thmax-thmin)/20;
    offx = offx_arr(a);
    offy = offy_arr(a);
    nmin = nmin+21;
    nmax = nmax+21;
        for n = nmin:nmax
            th(n) = thmin+dth*(n-(21*(a-1)+1));
            expl3b_x(n) = r*cosd(th(n))+offx;
            expl3b_y(n) = r*sind(th(n))+offy;
        end
    end
    %Concatenate x and y coords
    expl3b_org = [expl3b_x;expl3b_y];
    end
    function [expl3c_org] = create_expl3c
    %Initial coords of curves (relative to center)
    x1 = [-2, 2]; %initial x
    y1 = [-1, 1]; %initial y
    
    %Offset values of curve centers
    offx_arr = [1/2,-1/2];
    offy_arr = [3/2,-3/2];
    
    %min and max values of theta
    thmin_arr = [180+atand(1/2),     atand(1/2)];
    thmax_arr = [-90+atand(1/2),-270+atand(1/2)];
    
    %Initialize nmin and nmax
    nmin = -20;
    nmax = 0;
    for a = 1:2
    %Calculate radius, angles, and offset values
    r = sqrt(y1(a)^2+x1(a)^2);
    thmin = thmin_arr(a);%atand(abs(y1(a)/x1(a)))+thmin_off;
    thmax = thmax_arr(a);%atand(abs(y2(a)/x2(a)))+thmax_off;
    dth = (thmax-thmin)/20;
    offx = offx_arr(a);
    offy = offy_arr(a);
    nmin = nmin+21;
    nmax = nmax+21;
        for n = nmin:nmax
            th(n) = thmin+dth*(n-(21*(a-1)+1));
            expl3c_x(n) = r*cosd(th(n))+offx;
            expl3c_y(n) = r*sind(th(n))+offy;
        end
    end
    %Concatenate x and y coords
    expl3c_org = 12/10*[expl3c_x;expl3c_y];
    end
end
%G_explosion
function [G_expl_org] = G_create_expl
%Initial coords of curves (relative to center)
x1 = [ 3, 0,-2,-4,-3, 2, 2, 4]; %initial x
y1 = [-3,-4,-4, 1, 3, 5, 2, 0]; %initial y

%Offset values of curve centers
offx_arr = [ 0,-3,-5,-3, 1, 2, 5, 3];
offy_arr = [-4,-3, 1, 4, 5, 3,-1,-3];

%min and max values of theta
thmin_arr = [ -45,270,180+atan2d(4,2),180-atan2d(1,4),...
     135,90-atan2d(2,5), 45,  0];
thmax_arr = [-135,180,180-atan2d(4,2), 90-atan2d(1,4),...
      45,  -atan2d(2,5),-45,-90];

%Initialize nmin and nmax
nmin = -10;
nmax = 0;
for a = 1:8
%Calculate radius, angles, and offset values
r = sqrt(y1(a)^2+x1(a)^2);
thmin = thmin_arr(a);
thmax = thmax_arr(a);
dth = (thmax-thmin)/10;
offx = offx_arr(a);
offy = offy_arr(a);
nmin = nmin+11;
nmax = nmax+11;
    for n = nmin:nmax
        th(n) = thmin+dth*(n-(11*(a-1)+1));
        expl_x(n) = r*cosd(th(n))+offx;
        expl_y(n) = r*sind(th(n))+offy;
    end
end
%Concatenate x and y coords
G_expl_org = 6/100*[expl_x;expl_y];
end
function [G_expl2_org] = G_create_expl2
%Create coords of expl2
%Initial coords of curves (relative to center)
x1 = [ 3,2, 1/2,-1,-3,-1,-1/2]; %initial x
y1 = [ 1,0,-5/2,-3, 0, 2, 5/2]; %initial y

%Offset values of curve centers
offx_arr = [-2,-5,-11/2,-2,4, 5, 7/2];
offy_arr = [-6,-3,  3/2, 5,4,-1,-9/2];

%min and max values of theta
thmin_arr = [   atand(1/3), 0,-90+atand(1/5),-90-atand(1/3),...
    -180, 90+atand(1/2), 90+atand(1/5)];
thmax_arr = [90+atand(1/3),90,    atand(1/5),   -atand(1/3),...
     -90,180+atand(1/2),180+atand(1/5)];

%Initialize nmin and nmax
nmin = -10;
nmax = 0;
for a = 1:7
%Calculate radius, angles, and offset values
r = sqrt(y1(a)^2+x1(a)^2);
thmin = thmin_arr(a);
thmax = thmax_arr(a);
dth = (thmax-thmin)/10;
offx = offx_arr(a);
offy = offy_arr(a);
nmin = nmin+11;
nmax = nmax+11;
    for n = nmin:nmax
        th(n) = thmin+dth*(n-(11*(a-1)+1));
        expl_x2(n) = r*cosd(th(n))+offx;
        expl_y2(n) = r*sind(th(n))+offy;
    end
end
%Concatenate x and y coords
G_expl2_org = 6/10*[expl_x2;expl_y2];
end
function [G_expl3a_org,G_expl3b_org,G_expl3c_org] = G_create_expl3
[G_expl3a_org] = create_expl3a;
[G_expl3b_org] = create_expl3b;
[G_expl3c_org] = create_expl3c;

    function [G_expl3a_org] = create_expl3a %done
    %Initial coords of curves (relative to center)
    x1 = [-1, 1,-1, 1]; %initial x
    y1 = [ 2,-2,-2, 2]; %initial y
    
    %Offset values of curve centers
    offx_arr = [ 3, 0, 0, 0]; %[-2,-5,-5,-5];
    offy_arr = [-3, 0, 4, 0]; %[-6,-3, 1,-3];
    
    %min and max values of theta
    thmin_arr = [  90+atand(1/2), -90+atand(1/2),270-atand(1/2),...
        90-atand(1/2),90-atand(1/2)];
    thmax_arr = [-180-atand(1/2),-270+atand(1/2),-90+atand(1/2),...
          -atand(1/2),  -atand(1/2)];
    
    %Initialize nmin and nmax
    nmin = -20;
    nmax = 0;
    for a = 1:4
    %Calculate radius, angles, and offset values
    r = sqrt(y1(a)^2+x1(a)^2);
    thmin = thmin_arr(a);%atand(abs(y1(a)/x1(a)))+thmin_off;
    thmax = thmax_arr(a);%atand(abs(y2(a)/x2(a)))+thmax_off;
    dth = (thmax-thmin)/20;
    offx = offx_arr(a);
    offy = offy_arr(a);
    nmin = nmin+21;
    nmax = nmax+21;
        for n = nmin:nmax
            th(n) = thmin+dth*(n-(21*(a-1)+1));
            expl3a_x(n) = r*cosd(th(n))+offx;
            expl3a_y(n) = r*sind(th(n))+offy;
        end
    end
    %Concatenate x and y coords
   G_expl3a_org = 1/2*[expl3a_x;expl3a_y];
    end
    function [G_expl3b_org] = create_expl3b
    %Initial coords of curves (relative to center)
    x1 = [ 1,-1,-1,-2]; %initial x
    y1 = [-2, 2, 1,-1]; %initial y
    
    %Offset values of curve centers
    offx_arr = [-3, 0, 3, 0];
    offy_arr = [ 1, 0, 0, 0];
    
    %min and max values of theta
    thmin_arr = [270+atand(1/2),90+atand(1/2), 90+atand(1/2),...
        -atand(1/2)];
    thmax_arr = [    atand(1/2),   atand(1/2),-90-atand(1/2),...
        -180+atand(1/2)];
    
    %Initialize nmin and nmax
    nmin = -20;
    nmax = 0;
    for a = 1:4
    %Calculate radius, angles, and offset values
    r = sqrt(y1(a)^2+x1(a)^2);
    thmin = thmin_arr(a);%atand(abs(y1(a)/x1(a)))+thmin_off;
    thmax = thmax_arr(a);%atand(abs(y2(a)/x2(a)))+thmax_off;
    dth = (thmax-thmin)/20;
    offx = offx_arr(a);
    offy = offy_arr(a);
    nmin = nmin+21;
    nmax = nmax+21;
        for n = nmin:nmax
            th(n) = thmin+dth*(n-(21*(a-1)+1));
            expl3b_x(n) = r*cosd(th(n))+offx;
            expl3b_y(n) = r*sind(th(n))+offy;
        end
    end
    %Concatenate x and y coords
    G_expl3b_org = 1/2*[expl3b_x;expl3b_y];
    end
    function [G_expl3c_org] = create_expl3c
    %Initial coords of curves (relative to center)
    x1 = [-2, 2]; %initial x
    y1 = [-1, 1]; %initial y
    
    %Offset values of curve centers
    offx_arr = [1/2,-1/2];
    offy_arr = [3/2,-3/2];
    
    %min and max values of theta
    thmin_arr = [180+atand(1/2),     atand(1/2)];
    thmax_arr = [-90+atand(1/2),-270+atand(1/2)];
    
    %Initialize nmin and nmax
    nmin = -20;
    nmax = 0;
    for a = 1:2
    %Calculate radius, angles, and offset values
    r = sqrt(y1(a)^2+x1(a)^2);
    thmin = thmin_arr(a);%atand(abs(y1(a)/x1(a)))+thmin_off;
    thmax = thmax_arr(a);%atand(abs(y2(a)/x2(a)))+thmax_off;
    dth = (thmax-thmin)/20;
    offx = offx_arr(a);
    offy = offy_arr(a);
    nmin = nmin+21;
    nmax = nmax+21;
        for n = nmin:nmax
            th(n) = thmin+dth*(n-(21*(a-1)+1));
            expl3c_x(n) = r*cosd(th(n))+offx;
            expl3c_y(n) = r*sind(th(n))+offy;
        end
    end
    %Concatenate x and y coords
    G_expl3c_org = 6/10*[expl3c_x;expl3c_y];
    end
end

function [Ball,xCoords,yCoords] = Ball2Ring(BallRad,Ball,BallPos)
R = BallRad;
r = 0.9*BallRad;
for n = 1:182
    if n < 92
        th(n) = -4+4*n;
        xCoords(n) = R*cosd(th(n));
        yCoords(n) = R*sind(th(n));
    else
        th(n) = th(n-1)-4;
        xCoords(n) = r*cosd(th(n));
        yCoords(n) = r*sind(th(n));
    end
end
delete(Ball)
Ball = patch(xCoords+BallPos(1),yCoords+BallPos(2),'w');
end
function [Ball] = Ring2Ball(BallRad,Ball,BallPos,markersize,BallColor)
delete(Ball)
Ball = line(BallPos(1),BallPos(2),'marker','.',...
    'markersize',markersize,'color',BallColor);
end

function [lasergun_p,lasergun_xCoords,lasergun_yCoords] = create_lasergun(BlockThickness,lightgray)
%Create coordinates
lasergun_xCoords = [2,-2,-2,-1.25,1.25,2];
lasergun_yCoords = [BlockThickness,BlockThickness,-2*BlockThickness,-3*BlockThickness,-3*BlockThickness,-2*BlockThickness];
%Create patch
lasergun_p = patch(lasergun_xCoords,lasergun_yCoords,lightgray);
end

function [heartX,heartY] = heart_coords
%First circle
th_min = -45;
th_max = 135;
r = 6;
for n = 1:180
    th(n) = th_min+n;
    heartX(n) = r*cosd(th(n))+6;
    heartY(n) = r*sind(th(n))+15.25;
end
heartX(181) = 0;
heartY(181) = 17.75;
th_min = 45;
th_max = 225;
for n = 182:362
    th(n) = th_min+(n-181);
    heartX(n) = r*cosd(th(n))-6;
    heartY(n) = r*sind(th(n))+15.25;
end
heartX(363) = 0;
heartY(363) = 0;

%Scale
heartX = 1/5*heartX;
heartY = 1/5*heartY;
end