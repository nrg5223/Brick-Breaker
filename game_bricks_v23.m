%game_brickwalls
clear
clc
close all

%IDEAS/NOTES
% - 

%CURRENT BUGS/PROBLEMS
% - cannot destroy the last brick with ghost power up, it bugs afterwards
% - ball's path becomes gradually more VERTICAL and cannot be changed...
% the cause is either speed change function or block-ball-contact function
% - error message: Output argument "horSect" (and maybe others) not assigned during call to
% "game_bricks_v23>locateBall".
% Output argument "vertSect" (and maybe others) not assigned during call to
% - error message: "game_bricks_v23>locateBall".
% this occurs when ghost ball travels to leftmost or rightmost column

%% SETUP

%Get screensize
screensize = get(0,'ScreenSize');
figwidth = screensize(3)/2;
figheight = screensize(4)-120;

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

pause(3)
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
lasergun_on = 0; %represents whether lasergun powerup is on
shots_left = 5; %number of shots available for lasergun power up
life_down = 0; %represents whether life brick has been hit
shiftDeath = 0; %represents whether death was caused by shift
exit = 0; %represents whether player has chosen to exit game
maxlvl = 3; %highest lvl number required to "win"

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
Nonexistent = 0;
Basic = 1;
Strong = 2;
StrongCracked = 3;
Steel = 4;
Boom = 5;
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
rnum = randi(round(100-bwidth/2));
linewidth = 6; %width of pongBlock
BlockThickness = linewidth/9.5; %thickness of Block                      

%POWER UP DATA
old_shots_left = 0; %equals shots_left if ghost powerup is activated
laserwidth = 8;
meterwidth = 8;
lasermeterdist = 5;
heartdist = 6; %distance between heart centers
%Create coords for heart patches
[heartX,heartY] = heart_coords;
heartShift = -0.5; %change in y position of heart after each iteration

%Coords for lvl patches
%Create coords
lvl_l1X = [0,0,1,1,3,3];
lvl_l1Y = [0,5,5,1,1,0];
lvl_vX = [5,4,5,5.5,6,7,6];
lvl_vY = [0,5,5,1.5,5,5,0];
lvl_l2X = [8,8,9,9,11,11];
lvl_l2Y = lvl_l1Y;
lvl_1X = [14,14,15,15];
lvl_1Y = [0,5,5,0];
lvl_2X = [13,13,15,15,13,13,16,16,14,14,16,16];
lvl_2Y = [0,3,3,4,4,5,5,2,2,1,1,0];
lvl_3X = [13,13,15,15,13,13,15,15,13,13,16,16];
lvl_3Y = [0,1,1,2,2,3,3,4,4,5,5,0];
lvl_4X = [13,13,14,14,15,15,16,16,15,15];
lvl_4Y = [2,5,5,3,3,5,5,0,0,2];
lvl_5X = [13,13,15,15,13,13,16,16,14,14,16,16];
lvl_5Y = [0,1,1,2,2,5,5,4,4,3,3,0];

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
[B1_p,R1_p,I_p,C_p,K1_p,B2_p,R2_p,E1_p,A_p,K2_p,E2_p,R3_p,tBall_p,...
    B1X,B1Y,R1X,R1Y,IX,IY,CX,CY,K1X,K1Y,...
    B2X,B2Y,R2X,R2Y,E1X,E1Y,AX,AY,K2X,K2Y,E2X,E2Y,R3X,R3Y] = animatebricks;

while exit ~= 1

%Main menu
[mode,start,exit] = mainmenu(darkred,white,pixperunit,xMin,yMin,keys,mouse,mode);

%Initialize
lives = 3; %number of lives
lvl = 0; %reset lvl

%"Delete" title screen by shifting all patches out of view
set(B1_p,'XData',B1X,'YData',B1Y+100);
set(R1_p,'XData',R1X,'YData',R1Y+100);
set(I_p,'XData',IX,'YData',IY+100);
set(C_p,'XData',CX,'YData',CY+100);
set(K1_p,'XData',K1X,'YData',K1Y+100);
set(B2_p,'XData',B2X,'YData',B2Y+100);
set(R2_p,'XData',R2X,'YData',R2Y+100);
set(E1_p,'XData',E1X,'YData',E1Y+100);
set(A_p,'XData',AX,'YData',AY+100);
set(K2_p,'XData',K2X,'YData',K2Y+100);
set(E2_p,'XData',E2X,'YData',E2Y+100);
set(R3_p,'XData',R3X,'YData',R3Y+100);
set(tBall_p,'XData',51,'YData',200);

if exit ~= 1 %wish there was a better way to do this...
%Create border
border = patch(borderX,borderY,'b');
%Create Block patch
BlockCenter = 0+bwidth/2+randi(rnum); %center of position of Block
Block = line([BlockCenter-bwidth/2,BlockCenter+bwidth/2],...
    [0 0],'linewidth',linewidth,'color',brightgreen);

%Create lvl (text) patch
    lvl_l1_p = patch(lvl_l1X+44.5,lvl_l1Y-15,white);
    lvl_v_p = patch(lvl_vX+44.5,lvl_vY-15,white);
    lvl_l2_p = patch(lvl_l2X+44.5,lvl_l2Y-15,white);
    pause(1)
    
%Create heart patches
for n = 1:lives
    %Create patch
    hearts(n) = patch(heartX+2/3*bThickness+heartdist*(n-1),heartY-15,pink);
    pause(0.25)
end

end %if exit ~= 1

while lvl < maxlvl && lives > 0 && exit ~= 1
%% LEVEL SETUP

lvl = lvl+1; %change lvl

if lvl == 1
[numBricksAcross,numBricksDown,numIT,brickWidth,brickDepth...
    vertBricksLeft,shift,bricksStatus,brickCornerYPos,...
    brickCornerXPos,bricks,reqBricks,brickCornerYPos_org,rBoom,...
    cBoom,rHeart,cHeart] = genlvl1(Boom,Ghost,...
    Laser,Life,Steel,StrongCracked,crackedbrickXCoords,...
    crackedbrickYCoords,StrongBrickColor,BoomBrickColor,GhostBrickColor,...
    LaserBrickColor,LifeBrickColor,SteelBrickColor,brickXCoords,brickYCoords);

lvl_num_p = patch(lvl_1X+44.5,lvl_1Y-15,white); %lvl number patch
pause(0.25)
 
elseif lvl == 2
[numBricksAcross,numBricksDown,numIT,brickWidth,brickDepth...
    vertBricksLeft,shift,bricksStatus,brickCornerYPos,...
    brickCornerXPos,bricks,reqBricks,brickCornerYPos_org,rBoom,...
    cBoom,rHeart,cHeart] = genlvl2(Boom,Ghost,...
    Laser,Life,Steel,StrongCracked,crackedbrickXCoords,...
    crackedbrickYCoords,StrongBrickColor,BoomBrickColor,GhostBrickColor,...
    LaserBrickColor,LifeBrickColor,SteelBrickColor,brickXCoords,...
    brickYCoords,Strong);
elseif lvl == 3
[numBricksAcross,numBricksDown,numIT,brickWidth,brickDepth...
    vertBricksLeft,shift,bricksStatus,brickCornerYPos,...
    brickCornerXPos,bricks,reqBricks,brickCornerYPos_org,rBoom,...
    cBoom,rHeart,cHeart] = genlvl3(Boom,Ghost,...
    Laser,Life,Steel,StrongCracked,crackedbrickXCoords,...
    crackedbrickYCoords,StrongBrickColor,BoomBrickColor,GhostBrickColor,...
    LaserBrickColor,LifeBrickColor,SteelBrickColor,brickXCoords,...
    brickYCoords,Strong);
elseif lvl == 4
    [numBricksAcross,numBricksDown,numIT,brickWidth,brickDepth...
    vertBricksLeft,shift,bricksStatus,brickCornerYPos,...
    brickCornerXPos,bricks,reqBricks,brickCornerYPos_org,rBoom,...
    cBoom,rHeart,cHeart] = genlvl4(Boom,Ghost,...
    Laser,Life,Steel,StrongCracked,crackedbrickXCoords,...
    crackedbrickYCoords,StrongBrickColor,BoomBrickColor,GhostBrickColor,...
    LaserBrickColor,LifeBrickColor,SteelBrickColor,brickXCoords,...
    brickYCoords,Strong);
elseif lvl == 5
    [numBricksAcross,numBricksDown,numIT,brickWidth,brickDepth...
    vertBricksLeft,shift,bricksStatus,brickCornerYPos,...
    brickCornerXPos,bricks,reqBricks,brickCornerYPos_org,rBoom,...
    cBoom,rHeart,cHeart] = genlvl5(Boom,Ghost,...
    Laser,Life,Steel,StrongCracked,crackedbrickXCoords,...
    crackedbrickYCoords,StrongBrickColor,BoomBrickColor,GhostBrickColor,...
    LaserBrickColor,LifeBrickColor,SteelBrickColor,brickXCoords,...
    brickYCoords,Strong)
end

%Set counter for number of required bricks
reqBricks = 0;
for c = 1:numBricksAcross
    for r = 1:numBricksDown
        if bricksStatus(r,c) ~= 0 && bricksStatus(r,c) ~= Steel
            reqBricks = reqBricks+1;
        end
    end
end

%Helps with debugging situations where the last brick is a powerup
testing = 0;
if testing == 1
if lvl == 1
   for r = 1:numBricksDown
       for c = 1:numBricksAcross
           if r == 2 && c == 6
               bricksStatus(r,c) = Ghost;
           elseif r == 2 && c == 3
           else
               delete(bricks(r,c))
               bricksStatus(r,c) = 0;
           end
       end
   end
end
reqBricks = 2;
end %if testing == 1

%change lvl number
if lvl ~= 1
    pause(0.5)
    delete(lvl_num_p)
    if lvl == 2
        lvl_num_p = patch(lvl_2X+44.5,lvl_2Y-15,white);
    elseif lvl == 3
        lvl_num_p = patch(lvl_3X+44.5,lvl_3Y-15,white);
    elseif lvl == 4
        lvl_num_p = patch(lvl_4X+44.5,lvl_4Y-15,white);
    elseif lvl == 5
        lvl_num_p = patch(lvl_5X+44.5,lvl_5Y-15,white);
    end
end

%% LOOP

while lives > 0 && reqBricks > 0 && exit ~= 1
countdown(white); %countdown before game starts

%Spawn Ball
rnumX = round(100-2*BallRad); %upper limit of randomized ball coordinate
rnumY = rnumX-round(numBricksDown*brickDepth);
BallPos = [BallRad+randi(rnumX),BallRad+randi(rnumY)];
%The following start position allows for corner scenario to be recreated
%BallPos = [80 34.5];
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

while stop ~= 1 && reqBricks > 0 && exit ~= 1
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
        [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left,reqBricks] = brickReact(numBricksDown,...
        horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
        StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
        crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
        up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
        Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
        BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left,reqBricks);
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
                BallPos,BlockCenter,bwidth,right,left, mode, auto);
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
        [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left,reqBricks] = brickReact(numBricksDown,...
        horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
        StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
        crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
        up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
        Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
        BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left,reqBricks);
        yDirection = up;
    end
else %ball is within bricks
    %switch to left
    if BallPos(1)+BallRad > maxX && xDirection == right
        BallVel(1) = -BallVel(1);
        change = inX;
        if vertSect ~= numBricksAcross %ball is not at rightmost "vertical section"  
            [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left,reqBricks] = brickReact(numBricksDown,...
            horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
            StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
            crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
            up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
            Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
            BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left,reqBricks);
        end
        xDirection = left;
    end
    %switch to right
    if BallPos(1)-BallRad < minX && xDirection == left
        BallVel(1) = -BallVel(1);
        change = inX;
        if vertSect ~= 1 %ball is not at leftmost "vertical section"
            [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left,reqBricks] = brickReact(numBricksDown,...
            horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
            StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
            crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
            up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
            Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
            BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left,reqBricks);
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
            [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left,reqBricks] = brickReact(numBricksDown,...
            horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
            StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
            crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
            up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
            Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
            BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left,reqBricks);
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
                [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left,reqBricks] = brickReact(numBricksDown,...
                horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
                StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
                crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
                up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
                Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
                BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left,reqBricks);
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
            reqBricks = reqBricks-1;
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
                        if bricksStatus(R,C) ~= Steel
                            reqBricks = reqBricks-1;
                        end
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
            reqBricks = reqBricks-1;
        elseif bricksStatus(horSect,vertSect) == Laser
            lasergun_on = 1;
            delete(bricks(horSect,vertSect))
            bricksStatus(horSect,vertSect) = 0;
            reqBricks = reqBricks-1;
        elseif bricksStatus(horSect,vertSect) == Life
            delete(bricks(horSect,vertSect))
            bricksStatus(horSect,vertSect) = 0;
            life_down = 1;
            reqBricks = reqBricks-1;
        end
        %Change velocities and directions
        BallVel(1) = -BallVel(1);
        BallVel(2) = -BallVel(2);
        xDirection = -xDirection;
        yDirection = -yDirection;
    end
end

    %Delete and reset lasergun
    if shots_left <= 0 && lasergun_on > 0 && L_time <= 2 %ghost power up has become active
        %Reset everything, delete patch
            delete(lasergun_p)
            lasergun_on = 0;
            L_time = 0;
            for n = 1:old_shots_left
                delete(lasermeter_p(6-n))
            end
            shots_left = 5;
    end
    %Lasergun animation (bottom layer patch, it comes before other patch
    %functions)
    if L_time == 2 %&& shots_left > 0
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
            if bricksStatus(target_row,c_Block) ~= Steel
                reqBricks = reqBricks-1;
            end
            bricksStatus(target_row,c_Block) = 0;
        end
        L_time = 0; %reset L_time
        if shots_left == 1
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
    elseif G_time <= max_G_time
    set(Ball,'XData',xCoords+BallPos(1),...
             'YData',yCoords+BallPos(2));
    end
    
    %Boom Explosion animation (must follow the ball reposition so the explosion
    %is always "on TOP" of the ball)
    if B_exploding == 1
        %Rename r and c
        row = rBoom;
        col = cBoom;
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
            N = 0;
        end
        N = N+1; %change n value for next iteration
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
    if G_time >= max_G_time
            %Rename N
            A = G_time-(max_G_time-1);
            %Use functions to animate
            if A == 1
                %Destroy brick in Ball's position if existent
                if horSect ~= 0 && horSect <= numBricksDown %Ball is within bricks
                %Update counter
                if bricksStatus(horSect,vertSect) ~= Steel && bricksStatus(horSect,vertSect) ~= 0
                    reqBricks = reqBricks-1;
                end
                if bricksStatus(horSect,vertSect) == Boom
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
                hearts(lives) = patch(heartX+2/3*bThickness+heartdist*(lives-1),heartY-15,pink);
            end
            life_down = 0; %reset life_down
            H_time = 0; %reset H_time
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
    
end %while stop ~= 1 && reqBricks > 0 && exit ~= 1

stop = 0; %reset stop
delete(Ball) %delete ball
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

if shiftDeath ~= 1 && lives > 1 %player has not lost
%Reset powerups
%Boom
if B_exploding == 1
	if reqBricks ~= 0
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
    B_exploding = 0; %reset B_exploding
    else
        
    %Finish Boom explosion if needed
    N_org = N; %N at time of ending game
    for n = 1:35-N_org
    %Boom Explosion animation
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
            N = 0;
        end
        N = N+1; %change n value for next iteration
        n = n+1; %counter
        pause(p)
    end
    end   
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
    delete(G_meter_p)
    if G_time >= max_G_time
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
    end
    G_time = 0;
end

%Heart
if life_down == 2
    delete(fallHeart_p)
    life_down = 0;
end
end %if lives > 1

pause(0.25)

%Lose heart animation
if shiftDeath ~= 1 && reqBricks > 0
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
elseif shiftDeath == 1 %death is by shift, delete all remaining hearts
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
end %if shiftDeath ~= 1 && reqBricks > 0

end %while lives > 0 && reqBricks > 0 && exit ~= 1

if lives == 0 %player has lost
GAMEOVER(white) %GAMEOVER animation
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
    delete(G_meter_p)
    if G_time >= max_G_time
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
    end
    G_time = 0;
end
%Heart
if life_down == 2
    delete(fallHeart_p)
    life_down = 0;
end
%Delete all other things on screen
delete(lvl_l1_p)
delete(lvl_v_p)
delete(lvl_l2_p)
delete(lvl_num_p)
delete(Block)
delete(border)
for r = 1:numBricksDown
    for c = 1:numBricksAcross
        if bricksStatus(r,c) ~= 0
        delete(bricks(r,c))
        end
    end
end

elseif lvl == maxlvl %player has won

    
    %Something cool happens here
    win_animation(white) %nice
    
    
    %reset screen
    delete(lvl_l1_p)
    delete(lvl_v_p)
    delete(lvl_l2_p)
    delete(lvl_num_p)
    delete(Block)
    delete(border)
    for n = 1:lives
        delete(hearts(n))
    end
    for r = 1:numBricksDown
    for c = 1:numBricksAcross
        if bricksStatus(r,c) ~= 0
        delete(bricks(r,c))
        end
    end
    end
     
end %if lives == 0

end %while lvl < maxlvl && lives > 0 && exit ~= 1

if exit ~= 1
%Player is returning to main menu, reset title (BRICK BREAKER) position
set(B1_p,'XData',B1X,'YData',B1Y);
set(R1_p,'XData',R1X,'YData',R1Y);
set(I_p,'XData',IX,'YData',IY);
set(C_p,'XData',CX,'YData',CY);
set(K1_p,'XData',K1X,'YData',K1Y);
set(B2_p,'XData',B2X,'YData',B2Y);
set(R2_p,'XData',R2X,'YData',R2Y);
set(E1_p,'XData',E1X,'YData',E1Y);
set(A_p,'XData',AX,'YData',AY);
set(K2_p,'XData',K2X,'YData',K2Y);
set(E2_p,'XData',E2X,'YData',E2Y);
set(R3_p,'XData',R3X,'YData',R3Y);
set(tBall_p,'XData',51,'YData',100);
end %if exit ~= 1
end %while exit ~= 1

credits(white,darkred)

%% FUNCTIONS

function [B1_p,R1_p,I_p,C_p,K1_p,B2_p,R2_p,E1_p,A_p,K2_p,E2_p,R3_p,tBall_p,...
    B1X,B1Y,R1X,R1Y,IX,IY,CX,CY,K1X,K1Y,...
    B2X,B2Y,R2X,R2Y,E1X,E1Y,AX,AY,K2X,K2Y,E2X,E2Y,R3X,R3Y] = animatebricks
background;
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
for n = 1:17+NUM
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

function [mode,start,exit] = mainmenu(darkred,white,pixperunit,xMin,yMin,keys,mouse,mode)
%Re-initialize mode
%mode = mouse; %default mode
mode = 1; % auto mode
%Create coords
scale = 1;
%Arrows
    LarrowX = scale*[0,0,4,4,3,3,1,3,3];
    LarrowY = scale*[0,4,4,0,0,3,2,1,0];
    RarrowX = -LarrowX;
    RarrowY = LarrowY;
%Mouse
    thmin = -268;
    thmax = 88;
    dth = 1;
    r = 1;
    for n = 1:thmax-thmin
        th(n) = thmin+dth*(n-1);
        mouseX(n) = 2*r*cosd(th(n));
        mouseY(n) = 3*r*sind(th(n));
    end
    mouseX = scale*[mouseX,mouseX(thmax-thmin),mouseX(1)];
    mouseY = scale*[mouseY,0.5,0.5];
%Highlight
highlightX = [-4,-4,8,8,-3,-3,7,7,-3,-3];
highlightY = [-6,6,6,-6,-6,-5,-5,5,5,-6];
%s_meter
s_meterX = [34-34,34-34,67.25-34,67.25-34];
s_meterY = [0,2,2,0];
%e_meter
e_meterX = [78-78,78-78,100.8-78,100.8-78];
e_meterY = s_meterY;

%Letters
A___X = [0,0,3,3,2,2,1,1,2,2,1,1];
A___Y = [0,5,5,0,0,2,2,3,3,4,4,0];
C___X = [0,0,3,3,1,1,3,3];
C___Y = [0,5,5,4,4,1,1,0];
E___X = [0,0,3,3,1,1,3,3,1,1,3,3];
E___Y = [0,5,5,4,4,3,3,2,2,1,1,0];
I___X = [1,1,2,2];
I___Y = [0,5,5,0];
L___X = [0,0,1,1,3,3];
L___Y = [0,5,5,1,1,0];
N___X = [0,0,1,2,2,3,3,2,1,1];
N___Y = [0,5,5,2.5,5,5,0,0,2.5,0];
O___X = [0,0,3,3,2,2,1,1,2,2];
O___Y = [0,5,5,0,0,4,4,1,1,0];
R___X = [0,0,3,3,2.5,2,2,1,1,2.5,3,3,2,2,1,1];
R___Y = [0,5,5,3.5,3,3,4,4,3,3,2.5,0,0,2,2,0];
S___X = [0,0,2,2,0,0,3,3,1,1,3,3];
S___Y = [0,1,1,2,2,5,5,4,4,3,3,0];
T___X = [1,1,0,0,3,3,2,2];
T___Y = [0,4,4,5,5,4,4,0];
X___X = [0,1,0,1,1.5,2,3,2,3,2,1.5,1];
X___Y = [0,2.5,5,5,3.5,5,5,2.5,0,0,1.5,0];

%Shifts and scale for words
contX = -2;
contY = 8;
contscale = 0.85;
startX = 34;
startY = 3;
startXscale = 1.75;
startYscale = 1.75;
exitX = 78;
exitY = startY;
exitscale = 1.75;
%NONwords
arrows_X = 2.5;
mouse_X = 16;

%Create patches
Larrow_p = patch(LarrowX+0,LarrowY-2,darkred);
Rarrow_p = patch(RarrowX+9,RarrowY-2,darkred);
mouse_p = patch(mouseX+18,mouseY,darkred);
highlight_p = patch(highlightX+mouse_X,highlightY,white);

C___p = patch((C___X+0)*contscale+contX,C___Y+contY,white);
O1___p = patch((O___X+4)*contscale+contX,O___Y+contY,white);
N___p = patch((N___X+8)*contscale+contX,N___Y+contY,white);
T___p = patch((T___X+12)*contscale+contX,T___Y+contY,white);
R1___p = patch((R___X+16)*contscale+contX,R___Y+contY,white);
O2___p = patch((O___X+20)*contscale+contX,O___Y+contY,white);
L___p = patch((L___X+24)*contscale+contX,L___Y+contY,white);
S1___p = patch((S___X+28)*contscale+contX,S___Y+contY,white);

S2___p = patch((S___X+0)*startXscale+startX,S___Y*startYscale+startY,darkred);
T1___p = patch((T___X+4)*startXscale+startX,T___Y*startYscale+startY,darkred);
A___p = patch((A___X+8)*startXscale+startX,A___Y*startYscale+startY,darkred);
R2___p = patch((R___X+12)*startXscale+startX,R___Y*startYscale+startY,darkred);
T2___p = patch((T___X+16)*startXscale+startX,T___Y*startYscale+startY,darkred);

E___p = patch((E___X+0)*exitscale+exitX,E___Y*exitscale+exitY,white);
X___p = patch((X___X+4)*exitscale+exitX,X___Y*exitscale+exitY,white);
I___p = patch((I___X+7)*exitscale+exitX,I___Y*exitscale+exitY,white);
T3___p = patch((T___X+10)*exitscale+exitX,T___Y*exitscale+exitY,white);


%Initialize
ready = 0;
exit = 0;
s_time = 0;
max_s_time = 100;
e_time = 0;
max_e_time = max_s_time;

%Delay loop
while ready ~= 1 && exit ~= 1
    %Get mouse location
    mousePos = get(0,'PointerLocation'); %gets pointer coordinates in pixels
    XPos = mousePos(1)/pixperunit+xMin; %x coordinate of pointer
    YPos = mousePos(2)/pixperunit+yMin; %y coordinate of pointer
    
    %Determine condition
    if XPos > 31 && XPos < 70 && YPos > -1 && YPos < 16
        %Mouse is over start, update start timer and meter
        s_time = s_time+1;
        if s_time == 1 %create s_meter patch
            s_meter = patch(s_meterX*s_time/max_s_time+34,s_meterY,darkred);
        elseif s_time <= max_s_time %update s_meter patch
            set(s_meter,'XData',s_meterX*s_time/max_s_time+34);
        else %time is up, delete s_meter
            delete(s_meter)
        end
    else %Mouse is not over start
        if s_time ~= 0 %delete s_meter
            delete(s_meter)
            s_time = 0; %reset s_time
        end  
    end
    
    if XPos > 75 && XPos < 104 && YPos > -1 && YPos < 16
        %Mouse if over exit, update exit timer and meter
        e_time = e_time+1;
        if e_time == 1 %create e_meter patch
            e_meter = patch(e_meterX*e_time/max_e_time+78,e_meterY,white);
        elseif e_time <= max_e_time %update e_meter patch
            set(e_meter,'XData',e_meterX*e_time/max_e_time+78);
        else %time is up, delete e_meter
            delete(e_meter)
        end
    else %Mouse is not over exit
        if e_time ~= 0 %delete e_meter
            delete(e_meter)
            e_time = 0; %reset e_time
        end  
    end
    
    if XPos > -2 && XPos < 11 && YPos > -7 && YPos < 7
        %Mouse is over arrows
        mode = keys;
        %Set highlight_p
        set(highlight_p,'XData',highlightX+arrows_X);
    elseif XPos > 11 && XPos < 26 && YPos > -7 && YPos < 7
        %Mouse is over mouse (lol thats funny right there)
        mode = mouse;
        %Set highlight_p
        set(highlight_p,'XData',highlightX+mouse_X);
    end

    %Check loop conditions
    if s_time == max_s_time
        ready = 1;
    elseif e_time == max_e_time
        exit = 1;
    end
    
pause(0.01) %reasonable pause, yeh?
end

%Delete everything
delete(Larrow_p) 
delete(Rarrow_p)
delete(mouse_p)
delete(highlight_p)
delete(C___p)
delete(O1___p)
delete(N___p)
delete(T___p)
delete(R1___p)
delete(O2___p)
delete(L___p)
delete(S1___p)
delete(S2___p)
delete(T1___p)
delete(A___p)
delete(R2___p)
delete(T2___p)
delete(E___p)
delete(X___p)
delete(I___p)
delete(T3___p)
if ready == 1
    delete(s_meter)
elseif exit == 1
    delete(e_meter)
end

start = 0; %reset start
mode; %output in case it isn't changed
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
    BlockCenter,bwidth,right,left, mode, auto)
x = BallPos(1)-BlockCenter;
if mode == auto
    if BallVel(1) > 0
        xDirection = right;
    else
        xDirection = left;
    end
    BallVel = BallVel;
else
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
end

function [bricksStatus,bricks,B_exploding,offx,offy,G_time,lasergun_on,shots_left,life_down,old_shots_left,reqBricks] = brickReact(numBricksDown,...
        horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
        StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
        crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
        up,down,left,right,change,inX,inY,Steel,brickWidth,brickDepth,...
        Nonexistent,offx,offy,B_exploding,G_time,Ghost,BallPos,Laser,...
        BlockCenter,BlockThickness,lightgray,lasergun_on,shots_left,Life,life_down,old_shots_left,reqBricks)
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

%Brick counter
if bricksStatus(r,c) ~= Strong && bricksStatus(r,c) ~= Steel &&...
   bricksStatus(r,c) ~= Boom
    reqBricks = reqBricks-1;
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
                    if bricksStatus(R,C) ~= Steel
                        reqBricks = reqBricks-1;
                    end
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
reqBricks;
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

pause(3)
delete(G__p)
delete(A__p)
delete(M__p)
delete(E1__p)
delete(O__p)
delete(V__p)
delete(E2__p)
delete(R__p)
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

function win_animation(white)

pause(0.5)
[y_p,o_p,u_p,w_p,i_p,n_p,excl_p] = youwin(white);
pause(0.25)
sparks
pause(1)
%Delete words
delete(y_p)
delete(o_p)
delete(u_p)
delete(w_p)
delete(i_p)
delete(n_p)
delete(excl_p)

function sparks
%Initialize
x01 = 30+randi(40);
y01 = 40+randi(40);
x02 = 30+randi(40);
y02 = 40+randi(40);
x03 = 30+randi(40);
y03 = 40+randi(40);

thmin = 45;
thmax = 135;
size = 12;
numSparks = 40;
for n = 1:numSparks
    th(n) = thmin+randi(thmax-thmin); %degrees
    v0(n) = .5+0.1*randi(5); %on an angle, arbritrary value, unitless
    vx0(n) = cos(th(n))*v0(n);
    vy0(n) = sin(th(n))*v0(n);
end
accl = -0.04; %y direction, arbritrary value, unitless

%Create patches
for n = 1:numSparks
    spark1_p(n) = line(0,0,'marker','.','markersize',size,...
        'color',[0.1*(randi(11)-1),0.1*(randi(11)-1),0.1*(randi(11)-1)]);
end

%Update patches
for t1 = 1:150
    for n = 1:numSparks
        %Update positions
        x(n) = x01+vx0(n)*t1;
        y(n) = y01+vy0(n)*t1+1/2*accl*t1^2;
        set(spark1_p(n),'XData',x(n),'YData',y(n));
    end
    if t1 > 15
        if t1 == 16
            %Create patches
            for n = 1:numSparks
            spark2_p(n) = line(0,0,'marker','.','markersize',size,...
            'color',[0.1*(randi(11)-1),0.1*(randi(11)-1),0.1*(randi(11)-1)]);
            end
        end  
    for n = 1:numSparks
        t2 = t1-15;
        %Update positions
        x(n) = x02+vx0(n)*t2;
        y(n) = y02+vy0(n)*t2+1/2*accl*t2^2;
        set(spark2_p(n),'XData',x(n),'YData',y(n));
    end
    end
    if t1 > 30
        if t1 == 31
            %Create patches
            for n = 1:numSparks
            spark3_p(n) = line(0,0,'marker','.','markersize',size,...
            'color',[0.1*(randi(11)-1),0.1*(randi(11)-1),0.1*(randi(11)-1)]);
            end
        end  
    for n = 1:numSparks
        t3 = t1-30;
        %Update positions
        x(n) = x03+vx0(n)*t3;
        y(n) = y03+vy0(n)*t3+1/2*accl*t3^2;
        set(spark3_p(n),'XData',x(n),'YData',y(n));
    end
    end
    pause(0.01) %pretty fair eh?
end

%Delete patches
for n = 1:numSparks
    delete(spark1_p(n))
    delete(spark2_p(n))
    delete(spark3_p(n))
end
end

function [y_p,o_p,u_p,w_p,i_p,n_p,excl_p] = youwin(white)
scale = 3.5;
%Create coords
yx =  [-3,-3,-4,-3,-2.5,-2,-1,-2,-2];
yy =  [0,2,5,5,3.5,5,5,2,0];
for n = 1:length(yx)
    yx(n) = yx(n)-1.5;
    yy(n) = yy(n)+0.5;
end
ox =  [0,0,3,3,1,1,2,2,1,1];
oy =  [0,5,5,0,0,1,1,4,4,0];
for n = 1:length(ox)
    ox(n) = ox(n)-1.5;
    oy(n) = oy(n)+0.5;
end
ux =  [4,4,5,5,6,6,7,7];
uy =  [0,5,5,1,1,5,5,0];
for n = 1:length(ux)
    ux(n) = ux(n)-1.5;
    uy(n) = uy(n)+0.5;
end
wx =  [-3,-4,-3,-2.5,-2,-1,-0.5,0,1,0,-1,-1.5,-2];
wy =  [-6,-1,-1,-3.5,-1,-1,-3.5,-1,-1,-6,-6,-3.5,-6];
for n = 1:length(wx)
    wx(n) = wx(n)-2.5;
    wy(n) = wy(n)+0.5;
end
ix =  [2,2,3,3];
iy =  [-6,-1,-1,-6];
for n = 1:length(ix)
    ix(n) = ix(n)-2.5;
    iy(n) = iy(n)+0.5;
end
nx =  [4,4,5,6,6,7,7,6,5,5];
ny =  [-6,-1,-1,-3.5,-1,-1,-6,-6,-3.5,-6];
for n = 1:length(nx)
    nx(n) = nx(n)-2.5;
    ny(n) = ny(n)+0.5;
end
excl_x =  [8,8,9,9,8,8,9,9];
excl_y =  [-6,-5,-5,-4,-4,-1,-1,-6];
for n = 1:length(excl_x)
    excl_x(n) = excl_x(n)-2.5;
    excl_y(n) = excl_y(n)+0.5;
end

%Create patches
y_p = patch(scale*yx+50,scale*yy+50,white);
o_p = patch(scale*ox+50,scale*oy+50,white);
u_p = patch(scale*ux+50,scale*uy+50,white);
w_p = patch(scale*wx+50,scale*wy+50,white);
i_p = patch(scale*ix+50,scale*iy+50,white);
n_p = patch(scale*nx+50,scale*ny+50,white);
excl_p = patch(scale*excl_x+50,scale*excl_y+50,white);

%Update patches
for n = 1:35
   scale = n/10;
   set(y_p,'XData',scale*yx+50,'YData',scale*yy+50);
   set(o_p,'XData',scale*ox+50,'YData',scale*oy+50);
   set(u_p,'XData',scale*ux+50,'YData',scale*uy+50);
   set(w_p,'XData',scale*wx+50,'YData',scale*wy+50);
   set(i_p,'XData',scale*ix+50,'YData',scale*iy+50);
   set(n_p,'XData',scale*nx+50,'YData',scale*ny+50);
   set(excl_p,'XData',scale*excl_x+50,'YData',scale*excl_y+50);
   pause(0.001)
end
end
end

function credits(white,darkred)
%Letters
AX = [0,0,3,3,2,2,1,1,2,2,1,1];
AY = [0,5,5,0,0,2,2,3,3,4,4,0];
BX = [0,0,3,  3,2.5,  3,3,1,1,2,2,1,1,2,2,1,1];
BY = [0,5,5,3.5,  3,2.5,0,0,1,1,2,2,3,3,4,4,0];
CX = [0,0,3,3,1,1,3,3];
CY = [0,5,5,4,4,1,1,0];
DX = [0,0,2,3,3,2,1,1,2,2,1,1];
DY = [0,5,5,4,1,0,0,1,1,4,4,0];
EX = [0,0,3,3,1,1,3,3,1,1,3,3];
EY = [0,5,5,4,4,3,3,2,2,1,1,0];
FX = [0,0,3,3,1,1,3,3,1,1];
FY = [0,5,5,4,4,3,3,2,2,0];
GX = [0,0,3,3,1,1,2,2,1.5,1.5,3,3];
GY = [0,5,5,4,4,1,1,2,  2,  3,3,0];
HX = [0,0,1,1,2,2,3,3,2,2,1,1];
HY = [0,5,5,3,3,5,5,0,0,2,2,0];
IX = [1,1,2,2];
IY = [0,5,5,0];
JX = [0,0,1,1,2,2,3,3];
JY = [0,2,2,1,1,5,5,0];
KX = [0,0,1,1,2,3,1.75,3,2,1,1];
KY = [0,5,5,3,5,5, 2.5,0,0,2,0];
LX = [0,0,1,1,3,3];
LY = [0,5,5,1,1,0];
MX = [0,0,1,2.5,4,5,5,4,  4,3,2,  1,1];
MY = [0,5,5,1.5,5,5,0,0,2.5,0,0,2.5,0];
NX = [0,0,1,  2,2,3,3,2,  1,1];
NY = [0,5,5,2.5,5,5,0,0,2.5,0];
OX = [0,0,3,3,2,2,1,1,2,2];
OY = [0,5,5,0,0,4,4,1,1,0];
PX = [0,0,3,3,1,1,2,2,1,1];
PY = [0,5,5,2,2,3,3,4,4,0];
RX = [0,0,3,3,2.5,2,2,1,1,2.5,3,3,2,2,1,1];
RY = [0,5,5,3.5,3,3,4,4,3,3,2.5,0,0,2,2,0];
SX = [0,0,2,2,0,0,3,3,1,1,3,3];
SY = [0,1,1,2,2,5,5,4,4,3,3,0];
TX = [1,1,0,0,3,3,2,2];
TY = [0,4,4,5,5,4,4,0];
VX = [1,0,1,1.5,2,3,2];
VY = [0,5,5,1.5,5,5,0];
XX = [0,  1,0,1,1.5,2,3,  2,3,2,1.5,1];
XY = [0,2.5,5,5,3.5,5,5,2.5,0,0,1.5,0];
YX = [1,1,0,1,1.5,2,3,2,2];
YY = [0,2,5,5,3.5,5,5,2,0];
scX = [1,1,2,2,1,1,2,2];
scY = [1,2,2,3,3,4,4,1];
exclX = [0,0,1,1,0,0,1,1];
exclY = [0,1,1,2,2,5,5,0];
slashX = [0,1,2,1];
slashY = [0,5,5,0];
zeroX = [0,0,3,3,1,1,2,2,1,1];
zeroY = [0,5,5,0,0,1,1,4,4,0];
oneX = IX;
oneY = IY;
twoX = [0,0,2,2,0,0,3,3,1,1,3,3];
twoY = [0,3,3,4,4,5,5,2,2,1,1,0];
threeX = [0,0,2,2,0,0,2,2,0,0,3,3];
threeY = [0,1,1,2,2,3,3,4,4,5,5,0];
fiveX = SX;
fiveY = SY;
eightX = [0,0,3,3,1,1,2,2,1,1,2,2,1,1];
eightY = [0,5,5,0,0,1,1,2,2,3,3,4,4,0];
nineX = [2,2,1,1,2,2,0,0,3,3];
nineY = [0,4,4,3,3,2,2,5,5,0];

%INSPIRATION
insp_scale = 2;
insp_X = 9;
insp_Y = 80;
patch((IX+0)*insp_scale+insp_X,IY*insp_scale+insp_Y,white);
patch((NX+3)*insp_scale+insp_X,NY*insp_scale+insp_Y,white);
patch((SX+7)*insp_scale+insp_X,SY*insp_scale+insp_Y,white);
patch((PX+11)*insp_scale+insp_X,PY*insp_scale+insp_Y,white);
patch((IX+14)*insp_scale+insp_X,IY*insp_scale+insp_Y,white);
patch((RX+17)*insp_scale+insp_X,RY*insp_scale+insp_Y,white);
patch((AX+21)*insp_scale+insp_X,AY*insp_scale+insp_Y,white);
patch((TX+25)*insp_scale+insp_X,TY*insp_scale+insp_Y,white);
patch((IX+28)*insp_scale+insp_X,IY*insp_scale+insp_Y,white);
patch((OX+31)*insp_scale+insp_X,OY*insp_scale+insp_Y,white);
patch((NX+35)*insp_scale+insp_X,NY*insp_scale+insp_Y,white);
patch((scX+38)*insp_scale+insp_X,scY*insp_scale+insp_Y,white);

%BRICK BREAKER FROM THE BLACKBERRY
bbf_scale = 0.75;
bbf_X = 2;
bbf_Y = 72.5;
patch((BX+0)*bbf_scale+bbf_X,BY*bbf_scale+bbf_Y,darkred);
patch((RX+4)*bbf_scale+bbf_X,RY*bbf_scale+bbf_Y,darkred);
patch((IX+7)*bbf_scale+bbf_X,IY*bbf_scale+bbf_Y,darkred);
patch((CX+10)*bbf_scale+bbf_X,CY*bbf_scale+bbf_Y,darkred);
patch((KX+14)*bbf_scale+bbf_X,KY*bbf_scale+bbf_Y,darkred);

patch((BX+21)*bbf_scale+bbf_X,BY*bbf_scale+bbf_Y,darkred);
patch((RX+25)*bbf_scale+bbf_X,RY*bbf_scale+bbf_Y,darkred);
patch((EX+29)*bbf_scale+bbf_X,EY*bbf_scale+bbf_Y,darkred);
patch((AX+33)*bbf_scale+bbf_X,AY*bbf_scale+bbf_Y,darkred);
patch((KX+37)*bbf_scale+bbf_X,KY*bbf_scale+bbf_Y,darkred);
patch((EX+41)*bbf_scale+bbf_X,EY*bbf_scale+bbf_Y,darkred);
patch((RX+45)*bbf_scale+bbf_X,RY*bbf_scale+bbf_Y,darkred);

patch((FX+52)*bbf_scale+bbf_X,FY*bbf_scale+bbf_Y,darkred);
patch((RX+56)*bbf_scale+bbf_X,RY*bbf_scale+bbf_Y,darkred);
patch((OX+60)*bbf_scale+bbf_X,OY*bbf_scale+bbf_Y,darkred);
patch((MX+64)*bbf_scale+bbf_X,MY*bbf_scale+bbf_Y,darkred);

patch((TX+73)*bbf_scale+bbf_X,TY*bbf_scale+bbf_Y,darkred);
patch((HX+77)*bbf_scale+bbf_X,HY*bbf_scale+bbf_Y,darkred);
patch((EX+81)*bbf_scale+bbf_X,EY*bbf_scale+bbf_Y,darkred);

patch((BX+88)*bbf_scale+bbf_X,BY*bbf_scale+bbf_Y,darkred);
patch((LX+92)*bbf_scale+bbf_X,LY*bbf_scale+bbf_Y,darkred);
patch((AX+96)*bbf_scale+bbf_X,AY*bbf_scale+bbf_Y,darkred);
patch((CX+100)*bbf_scale+bbf_X,CY*bbf_scale+bbf_Y,darkred);
patch((KX+104)*bbf_scale+bbf_X,KY*bbf_scale+bbf_Y,darkred);
patch((BX+108)*bbf_scale+bbf_X,BY*bbf_scale+bbf_Y,darkred);
patch((EX+112)*bbf_scale+bbf_X,EY*bbf_scale+bbf_Y,darkred);
patch((RX+116)*bbf_scale+bbf_X,RY*bbf_scale+bbf_Y,darkred);
patch((RX+120)*bbf_scale+bbf_X,RY*bbf_scale+bbf_Y,darkred);
patch((YX+124)*bbf_scale+bbf_X,YY*bbf_scale+bbf_Y,darkred);

%START & FINISH
stfn_scale = 1;
st_X = 6.5;
fn_X = 66.5;
stfn_Y = 50;
patch((SX+0)*stfn_scale+st_X,SY*stfn_scale+stfn_Y,white);
patch((TX+4)*stfn_scale+st_X,TY*stfn_scale+stfn_Y,white);
patch((AX+8)*stfn_scale+st_X,AY*stfn_scale+stfn_Y,white);
patch((RX+12)*stfn_scale+st_X,RY*stfn_scale+stfn_Y,white);
patch((TX+16)*stfn_scale+st_X,TY*stfn_scale+stfn_Y,white);
patch((EX+20)*stfn_scale+st_X,EY*stfn_scale+stfn_Y,white);
patch((DX+24)*stfn_scale+st_X,DY*stfn_scale+stfn_Y,white);
line([6.5,33.5],[stfn_Y-1,stfn_Y-1],'linewidth',3,'color',white)

patch((FX+0)*stfn_scale+fn_X,FY*stfn_scale+stfn_Y,white);
patch((IX+3)*stfn_scale+fn_X,IY*stfn_scale+stfn_Y,white);
patch((NX+6)*stfn_scale+fn_X,NY*stfn_scale+stfn_Y,white);
patch((IX+9)*stfn_scale+fn_X,IY*stfn_scale+stfn_Y,white);
patch((SX+12)*stfn_scale+fn_X,SY*stfn_scale+stfn_Y,white);
patch((HX+16)*stfn_scale+fn_X,HY*stfn_scale+stfn_Y,white);
patch((EX+20)*stfn_scale+fn_X,EY*stfn_scale+stfn_Y,white);
patch((DX+24)*stfn_scale+fn_X,DY*stfn_scale+stfn_Y,white);
line([66.5,93.5],[stfn_Y-1,stfn_Y-1],'linewidth',3,'color',white)

%DATES
date_scale = 1.25;
stdt_X = 5.5;
fndt_X = 67;
date_Y = 40;

patch((fiveX+0)*date_scale+stdt_X,fiveY*date_scale+date_Y,darkred);
patch((slashX+4)*date_scale+stdt_X,slashY*date_scale+date_Y,darkred);
patch((oneX+6)*date_scale+stdt_X,oneY*date_scale+date_Y,darkred);
patch((threeX+9)*date_scale+stdt_X,threeY*date_scale+date_Y,darkred);
patch((slashX+13)*date_scale+stdt_X,slashY*date_scale+date_Y,darkred);
patch((twoX+16)*date_scale+stdt_X,twoY*date_scale+date_Y,darkred);
patch((zeroX+20)*date_scale+stdt_X,zeroY*date_scale+date_Y,darkred);

patch((eightX+0)*date_scale+fndt_X,eightY*date_scale+date_Y,darkred);
patch((slashX+4)*date_scale+fndt_X,slashY*date_scale+date_Y,darkred);
patch((nineX+7)*date_scale+fndt_X,nineY*date_scale+date_Y,darkred);
patch((slashX+11)*date_scale+fndt_X,slashY*date_scale+date_Y,darkred);
patch((twoX+14)*date_scale+fndt_X,twoY*date_scale+date_Y,darkred);
patch((zeroX+18)*date_scale+fndt_X,zeroY*date_scale+date_Y,darkred);

%PROGRAMMED BY
prog_scale = 1;
progX = 5;
progY = 10;
patch((PX+0)*prog_scale+progX,PY*prog_scale+progY,white);
patch((RX+4)*prog_scale+progX,RY*prog_scale+progY,white);
patch((OX+8)*prog_scale+progX,OY*prog_scale+progY,white);
patch((GX+12)*prog_scale+progX,GY*prog_scale+progY,white);
patch((RX+16)*prog_scale+progX,RY*prog_scale+progY,white);
patch((AX+20)*prog_scale+progX,AY*prog_scale+progY,white);
patch((MX+24)*prog_scale+progX,MY*prog_scale+progY,white);
patch((MX+30)*prog_scale+progX,MY*prog_scale+progY,white);
patch((EX+36)*prog_scale+progX,EY*prog_scale+progY,white);
patch((DX+40)*prog_scale+progX,DY*prog_scale+progY,white);
patch((BX+48)*prog_scale+progX,BY*prog_scale+progY,white);
patch((YX+52)*prog_scale+progX,YY*prog_scale+progY,white);

%NICK GROSSKOPF
ng_scale = 1.5;
ngX = 15;
ngY = -5;
patch((NX+1)*ng_scale+ngX,NY*ng_scale+ngY,darkred);
patch((IX+4)*ng_scale+ngX,IY*ng_scale+ngY,darkred);
patch((CX+7)*ng_scale+ngX,CY*ng_scale+ngY,darkred);
patch((KX+11)*ng_scale+ngX,KY*ng_scale+ngY,darkred);
patch((GX+19)*ng_scale+ngX,GY*ng_scale+ngY,darkred);
patch((RX+23)*ng_scale+ngX,RY*ng_scale+ngY,darkred);
patch((OX+27)*ng_scale+ngX,OY*ng_scale+ngY,darkred);
patch((SX+31)*ng_scale+ngX,SY*ng_scale+ngY,darkred);
patch((SX+35)*ng_scale+ngX,SY*ng_scale+ngY,darkred);
patch((KX+39)*ng_scale+ngX,KY*ng_scale+ngY,darkred);
patch((OX+43)*ng_scale+ngX,OY*ng_scale+ngY,darkred);
patch((PX+47)*ng_scale+ngX,PY*ng_scale+ngY,darkred);
patch((FX+51)*ng_scale+ngX,FY*ng_scale+ngY,darkred);
end

% 5 checkered rows cracked, 1 power up
function [numBricksAcross,numBricksDown,numIT,brickWidth,brickDepth...
    vertBricksLeft,shift,bricksStatus,brickCornerYPos,...
    brickCornerXPos,bricks,reqBricks,brickCornerYPos_org,rBoom,...
    cBoom,rHeart,cHeart] = genlvl1(Boom,Ghost,...
    Laser,Life,Steel,StrongCracked,crackedbrickXCoords,...
    crackedbrickYCoords,StrongBrickColor,BoomBrickColor,GhostBrickColor,...
    LaserBrickColor,LifeBrickColor,SteelBrickColor,brickXCoords,brickYCoords)
%RE-INITIALIZE BRICK DATA
numBricksAcross = 7;
numBricksDown = 5;
numIT = 1; %this location for numIT reset is questionable, but this was its
           %previous location relative to what's around it
brickWidth = 100/numBricksAcross; %width of bricks(DEPENDENT)
brickDepth = 8.75; %depth of bricks (MANUAL)
numBricks = numBricksAcross*numBricksDown; %number of bricks (10 x 4 grid)
vertBricksLeft = numBricksDown; %represents number of bricks left
                               %in "vertical section"
for n = 2:numBricksAcross
vertBricksLeft = [vertBricksLeft,numBricksDown]; %"add" another element
end
shift = 0; %reset shift

%Delete every other brick
for r = 1:numBricksDown
    for c = 1:numBricksAcross
        if r/2 == round(r/2) && c/2 ~= round(c/2) ||...
           r/2 ~= round(r/2) && c/2 == round(c/2)
            %Delete brick
            bricksStatus(r,c) = 0;
        else
            bricksStatus(r,c) = StrongCracked;
        end
    end
end

%Special bricks
whichPU = randi(4); %variable to choose a power up randomly
if whichPU == 1
    rGhost = 0;
    cGhost = 0;
    rLaser = 0;
    cLaser = 0;
    rHeart = 0;
    cHeart = 0;
    %Make one random brick Boom
    rBoom = 1; %arbitrary values for the loop to start
    cBoom = 1;
    while bricksStatus(rBoom,cBoom) ~= Boom
        %Randomized row and column of Boom brick's position
        rBoom = 1+randi(numBricksDown-2); %prevents r from being on the end 
        cBoom = 1+randi(numBricksAcross-2); %prevents c from being on the end
        if bricksStatus(rBoom,cBoom) ~= 0
            bricksStatus(rBoom,cBoom) = Boom;
        end
        BoomBrickPos = [rBoom,cBoom]; %save position of Boom Brick
    end
elseif whichPU == 2
    rBoom = 0;
    cBoom = 0;
    rLaser = 0;
    cLaser = 0;
    rHeart = 0;
    cHeart = 0;
%Make one random brick Ghost
    rGhost = 1; %arbitrary values for the loop to start
    cGhost = 1;
    while bricksStatus(rGhost,cGhost) ~= Ghost
        %Randomized row and column of Ghost brick's position
        rGhost = 1+randi(numBricksDown-2); %prevents r from being on the end 
        cGhost = 1+randi(numBricksAcross-2); %prevents c from being on the end
        if bricksStatus(rGhost,cGhost) ~= 0
            bricksStatus(rGhost,cGhost) = Ghost;
        end
    end
elseif whichPU == 3
    rBoom = 0;
    cBoom = 0;
    rGhost = 0;
    cGhost = 0;
    rHeart = 0;
    cHeart = 0;
%Make one random brick Laser
    rLaser = 1; %arbitrary values for the loop to start
    cLaser = 1;
    while bricksStatus(rLaser,cLaser) ~= Laser
        %Randomized row and column of Laser brick's position
        rLaser = 1+randi(numBricksDown-2); %prevents r from being on the end 
        cLaser = 1+randi(numBricksAcross-2); %prevents c from being on the end
        if bricksStatus(rLaser,cLaser) ~= 0
            bricksStatus(rLaser,cLaser) = Laser;
        end
    end
elseif whichPU == 4
    rBoom = 0;
    cBoom = 0;
    rGhost = 0;
    cGhost = 0;
    rLaser = 0;
    cLaser = 0;
%Make one random brick Heart
    rHeart = 1; %arbitrary values for the loop to start
    cHeart = 1;
    while bricksStatus(rHeart,cHeart) ~= Life
        %Randomized row and column of Heart brick's position
        rHeart = 1+randi(numBricksDown-2); %prevents r from being on the end 
        cHeart = 1+randi(numBricksAcross-2); %prevents c from being on the end
        if bricksStatus(rHeart,cHeart) ~= 0
            bricksStatus(rHeart,cHeart) = Life;
        end
    end
end %if whichPU == 1

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
        if bricksStatus(r,c) == 0
            %Don't do anything
        else
            bricks(r,c) = patch(crackedbrickXCoords+brickCornerXPos(r,c),...
                                crackedbrickYCoords+brickCornerYPos(r,c),StrongBrickColor);
            bricksStatus(r,c) = StrongCracked;
        end
    end
    pause(0.05)
    end
end

%Set counter for number of required bricks
reqBricks = 0;
for c = 1:numBricksAcross
    for r = 1:numBricksDown
        if bricksStatus(r,c) ~= 0 && bricksStatus(r,c) ~= Steel
            reqBricks = reqBricks+1;
        end
    end
end

end

% 2 rows strong, 2 rows cracked, 2 power ups
function [numBricksAcross,numBricksDown,numIT,brickWidth,brickDepth...
    vertBricksLeft,shift,bricksStatus,brickCornerYPos,...
    brickCornerXPos,bricks,reqBricks,brickCornerYPos_org,rBoom,...
    cBoom,rHeart,cHeart] = genlvl2(Boom,Ghost,...
    Laser,Life,Steel,StrongCracked,crackedbrickXCoords,...
    crackedbrickYCoords,StrongBrickColor,BoomBrickColor,GhostBrickColor,...
    LaserBrickColor,LifeBrickColor,SteelBrickColor,brickXCoords,...
    brickYCoords,Strong)
%Arbitrary values for backup output
rBoom = 0;
cBoom = 0;
rHeart = 0;
cHeart = 0;
%RE-INITIALIZE BRICK DATA
numBricksAcross = 7;
numBricksDown = 4;

numIT = 1; %this location for numIT reset is questionable, but this was its
           %previous location relative to what's around it

brickWidth = 100/numBricksAcross; %width of bricks(DEPENDENT)
brickDepth = 8.75; %depth of bricks (MANUAL)
numBricks = numBricksAcross*numBricksDown; %number of bricks (10 x 4 grid)
vertBricksLeft = numBricksDown; %represents number of bricks left
                               %in "vertical section"
for n = 2:numBricksAcross
vertBricksLeft = [vertBricksLeft,numBricksDown]; %"add" another element
end
shift = 0; %reset shift
bricksStatus = zeros(numBricksDown,numBricksAcross);

%Special bricks
%Delete two special bricks
deleteThis1 = 4+randi(4); %first one
deleteThis2 = deleteThis1; %second one
while deleteThis2 == deleteThis1
deleteThis2 = 4+randi(4);
end
BoomBrickPos = [0,0]; %arbitrary
if Boom ~= deleteThis1 && Boom ~= deleteThis2
%Make one random brick Boom
%Randomized row and column of Boom brick's position
rBoom = 1+randi(numBricksDown-2); %prevents r from being on the end 
cBoom = 1+randi(numBricksAcross-2); %prevents c from being on the end
bricksStatus(rBoom,cBoom) = Boom;
BoomBrickPos = [rBoom,cBoom]; %save position of Boom Brick
end
GhostBrickPos = [0,0]; %arbitrary
if Ghost ~= deleteThis1 && Ghost ~= deleteThis2
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
end
LaserBrickPos = [0,0]; %arbitrary
if Laser ~= deleteThis1 && Laser ~= deleteThis2
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
end
if Life ~= deleteThis1 && Life ~= deleteThis2
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
end

%Create initial brick patches
for r = 1:numBricksDown
    for c = 1:numBricksAcross
    brickCornerXPos(r,c) = brickWidth*(c-1);
    brickCornerYPos(r,c) = 100-brickDepth*r+shift;
    %Create "original" variable for brickCornerYPos
    brickCornerYPos_org(r,c) = 100-brickDepth*r; %no shift in this array
    if bricksStatus(r,c) == Boom
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),BoomBrickColor);
    elseif bricksStatus(r,c) == Ghost
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),GhostBrickColor);
    elseif bricksStatus(r,c) == Laser
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),LaserBrickColor);
    elseif bricksStatus(r,c) == Life
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),LifeBrickColor);
    else
        if r < 3
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),StrongBrickColor);
        bricksStatus(r,c) = Strong;
        else
        bricks(r,c) = patch(crackedbrickXCoords+brickCornerXPos(r,c),...
                     crackedbrickYCoords+brickCornerYPos(r,c),StrongBrickColor);
        bricksStatus(r,c) = StrongCracked;
        end
    end
    pause(0.05)
    end
end

%Set counter for number of required bricks
reqBricks = 0;
for c = 1:numBricksAcross
    for r = 1:numBricksDown
        if bricksStatus(r,c) ~= 0 && bricksStatus(r,c) ~= Steel
            reqBricks = reqBricks+1;
        end
    end
end
end

% 5 rows strong, 2 pairs steel, 3 power ups
function [numBricksAcross,numBricksDown,numIT,brickWidth,brickDepth...
    vertBricksLeft,shift,bricksStatus,brickCornerYPos,...
    brickCornerXPos,bricks,reqBricks,brickCornerYPos_org,rBoom,...
    cBoom,rHeart,cHeart] = genlvl3(Boom,Ghost,...
    Laser,Life,Steel,StrongCracked,crackedbrickXCoords,...
    crackedbrickYCoords,StrongBrickColor,BoomBrickColor,GhostBrickColor,...
    LaserBrickColor,LifeBrickColor,SteelBrickColor,brickXCoords,...
    brickYCoords,Strong)
%Arbitrary values for backup output
rBoom = 0;
cBoom = 0;
rHeart = 0;
cHeart = 0;
%RE-INITIALIZE BRICK DATA
numBricksAcross = 7;
numBricksDown = 5;

numIT = 1; %this location for numIT reset is questionable, but this was its
           %previous location relative to what's around it

brickWidth = 100/numBricksAcross; %width of bricks(DEPENDENT)
brickDepth = 8.75; %depth of bricks (MANUAL)
numBricks = numBricksAcross*numBricksDown; %number of bricks (10 x 4 grid)
vertBricksLeft = numBricksDown; %represents number of bricks left
                               %in "vertical section"
for n = 2:numBricksAcross
vertBricksLeft = [vertBricksLeft,numBricksDown]; %"add" another element
end
shift = 0; %reset shift
bricksStatus = zeros(numBricksDown,numBricksAcross);
for c = 2:6
    if c ~= 4
    bricksStatus(2,c) = Steel;
    end
end

%Special bricks
%Delete one special brick
deleteThis1 = 4+randi(4);

%Boom
BoomBrickPos = [0,0]; %arbitrary
if Boom ~= deleteThis1
diff = 0; %represents whether BoomBrickPos is same as steel brick positions
while diff ~= 1
rBoom = 1+randi(numBricksDown-2);
cBoom = 1+randi(numBricksAcross-2);
BoomBrickPos = [rBoom,cBoom]; %save position of Ghost Brick
if bricksStatus(rBoom,cBoom) ~= Steel
    diff = 1;
end
end
bricksStatus(rBoom,cBoom) = Boom;
BoomBrickPos = [rBoom,cBoom]; %save position of Boom Brick
end

%Ghost
GhostBrickPos = [0,0]; %arbitrary
if Ghost ~= deleteThis1
%Make one random brick Ghost
diff = 0; %represents whether GhostBrickPos is same as BoomBrickPos
while diff ~= 1
rGhost = randi(numBricksDown);
cGhost = randi(numBricksAcross);
GhostBrickPos = [rGhost,cGhost]; %save position of Ghost Brick
bricksStatus(3,4)
    if GhostBrickPos ~= BoomBrickPos
    if bricksStatus(rGhost,cGhost) ~= Steel
    diff = 1;
    end
	end
end
bricksStatus(rGhost,cGhost) = Ghost;
end

%Laser
LaserBrickPos = [0,0]; %arbitrary
if Laser ~= deleteThis1
diff = 0; 
while diff ~= 1
rLaser = randi(numBricksDown);
cLaser = randi(numBricksAcross);
LaserBrickPos = [rLaser,cLaser]; %save position of Laser Brick
if LaserBrickPos ~= BoomBrickPos
    if LaserBrickPos ~= GhostBrickPos
    if bricksStatus(rLaser,cLaser) ~= Steel
        diff = 1;
    end
    end
end
end
bricksStatus(rLaser,cLaser) = Laser;
end

%Life
%(doesn't need arbitrary value)
if Life ~= deleteThis1
%Make one random brick Life
diff = 0; 
while diff ~= 1
rHeart = randi(numBricksDown);
cHeart = randi(numBricksAcross);
LifeBrickPos = [rHeart,cHeart]; %save position of Laser Brick
if LifeBrickPos ~= BoomBrickPos
    if LifeBrickPos ~= GhostBrickPos
        if LifeBrickPos ~= LaserBrickPos
        if bricksStatus(rHeart,cHeart) ~= Steel
            diff = 1;
        end
        end
    end
end
end
bricksStatus(rHeart,cHeart) = Life;
end

%Create initial brick patches
for r = 1:numBricksDown
    for c = 1:numBricksAcross
    brickCornerXPos(r,c) = brickWidth*(c-1);
    brickCornerYPos(r,c) = 100-brickDepth*r+shift;
    %Create "original" variable for brickCornerYPos
    brickCornerYPos_org(r,c) = 100-brickDepth*r; %no shift in this array
    if bricksStatus(r,c) == Boom
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),BoomBrickColor);
    elseif bricksStatus(r,c) == Ghost
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),GhostBrickColor);
    elseif bricksStatus(r,c) == Laser
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),LaserBrickColor);
    elseif bricksStatus(r,c) == Life
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),LifeBrickColor);
    elseif bricksStatus(r,c) == Steel
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),SteelBrickColor);
    else
    bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),StrongBrickColor);
    bricksStatus(r,c) = 2;
    end
    pause(0.05)
    end
end

%Set counter for number of required bricks
reqBricks = 0;
for c = 1:numBricksAcross
    for r = 1:numBricksDown
        if bricksStatus(r,c) ~= 0 && bricksStatus(r,c) ~= Steel
            reqBricks = reqBricks+1;
        end
    end
end
end

% (scrapped) 5 rows cracked, 2 power ups
function [numBricksAcross,numBricksDown,numIT,brickWidth,brickDepth...
    vertBricksLeft,shift,bricksStatus,brickCornerYPos,...
    brickCornerXPos,bricks,reqBricks,brickCornerYPos_org,rBoom,...
    cBoom,rHeart,cHeart] = genlvl_idk(Boom,Ghost,...
    Laser,Life,Steel,StrongCracked,crackedbrickXCoords,...
    crackedbrickYCoords,StrongBrickColor,BoomBrickColor,GhostBrickColor,...
    LaserBrickColor,LifeBrickColor,SteelBrickColor,brickXCoords,...
    brickYCoords,Strong)
%Arbitrary values for backup output
rBoom = 0;
cBoom = 0;
rHeart = 0;
cHeart = 0;
%RE-INITIALIZE BRICK DATA
numBricksAcross = 7;
numBricksDown = 5;

numIT = 1; %this location for numIT reset is questionable, but this was its
           %previous location relative to what's around it

brickWidth = 100/numBricksAcross; %width of bricks(DEPENDENT)
brickDepth = 8.75; %depth of bricks (MANUAL)
numBricks = numBricksAcross*numBricksDown; %number of bricks (10 x 4 grid)
vertBricksLeft = numBricksDown; %represents number of bricks left
                               %in "vertical section"
for n = 2:numBricksAcross
vertBricksLeft = [vertBricksLeft,numBricksDown]; %"add" another element
end
shift = 0; %reset shift
bricksStatus = zeros(numBricksDown,numBricksAcross);

%Special bricks
%Delete two special bricks
deleteThis1 = 4+randi(4); %first one
deleteThis2 = deleteThis1; %second one
while deleteThis2 == deleteThis1
deleteThis2 = 4+randi(4);
end
BoomBrickPos = [0,0]; %arbitrary
if Boom ~= deleteThis1 && Boom ~= deleteThis2
%Make one random brick Boom
%Randomized row and column of Boom brick's position
rBoom = 1+randi(numBricksDown-2); %prevents r from being on the end 
cBoom = 1+randi(numBricksAcross-2); %prevents c from being on the end
bricksStatus(rBoom,cBoom) = Boom;
BoomBrickPos = [rBoom,cBoom]; %save position of Boom Brick
end
GhostBrickPos = [0,0]; %arbitrary
if Ghost ~= deleteThis1 && Ghost ~= deleteThis2
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
end
LaserBrickPos = [0,0]; %arbitrary
if Laser ~= deleteThis1 && Laser ~= deleteThis2
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
end
if Life ~= deleteThis1 && Life ~= deleteThis2
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
end

%Create initial brick patches
for r = 1:numBricksDown
    for c = 1:numBricksAcross
    brickCornerXPos(r,c) = brickWidth*(c-1);
    brickCornerYPos(r,c) = 100-brickDepth*r+shift;
    %Create "original" variable for brickCornerYPos
    brickCornerYPos_org(r,c) = 100-brickDepth*r; %no shift in this array
    if bricksStatus(r,c) == Boom
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),BoomBrickColor);
    elseif bricksStatus(r,c) == Ghost
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),GhostBrickColor);
    elseif bricksStatus(r,c) == Laser
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),LaserBrickColor);
    elseif bricksStatus(r,c) == Life
        bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),LifeBrickColor);
    else
    bricks(r,c) = patch(crackedbrickXCoords+brickCornerXPos(r,c),...
                     crackedbrickYCoords+brickCornerYPos(r,c),StrongBrickColor);
    bricksStatus(r,c) = StrongCracked;
    end
    pause(0.05)
    end
end

%Set counter for number of required bricks
reqBricks = 0;
for c = 1:numBricksAcross
    for r = 1:numBricksDown
        if bricksStatus(r,c) ~= 0 && bricksStatus(r,c) ~= Steel
            reqBricks = reqBricks+1;
        end
    end
end
end
