%game_brickwalls
clear
clc
close all

%IDEAS/NOTES
% - start date was about 5/13/2020
% - I didn't want to do this...but I got an AWESOME idea for a title
% screen: two large bricks with which a ball collides, causing them to
% break up into shapes of the letters in BRICK BREAKER
% - make main menu screen and start button
% - make adjustable sensitivities
% - different levels (5 or 10 depending on how much I care...probably 5)
% - GOLDEN BRICK: when destroyed, explodes and destroys the surrounding
%   bricks
% - power ups (maybe): longer block (change bwidth and color of block),
% exploding or enlarged ball, decrease ball speed, reset brick position to
% top, ball explodes into multiple smaller balls (either smaller ones of a
% different color that cannot be controlled/hit or multiple balls identical
% to the regular one which may all be controlled/hit,
% wrecking ball that goes through a line of bricks, laser ability that lets
% user push space bar to shoot laser towards bricks, heat-seeking ball that
% accelerates towards nearest brick (this one's interesting...)
% - change velocity and pause values proportionally to optimize ball motion
% "smoothness" and minimize chance for brick-ball contact bug

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
xMinAxesRat = 0.05;
xMaxAxesRat = 0.9;
yMinAxesRat = 0.05;
yMaxAxesRat = 0.9;
%Create axes
brickwallsAxes = axes('XLim',[0 100],'YLim',[-5 100],...
    'color','black',...
    'XTickLabels',[],'YTickLabels',[],...
    'position',[xMinAxesRat,yMinAxesRat,xMaxAxesRat,yMaxAxesRat]);
grid on

%Pixels to axes units
%totalPix = (xMaxAxesRat-0.1)*figwidth;
%totalAxesUnits = 100;
%pix2axesUnits = totalAxesUnits/(totalPix); %multiply a coordinate in pixels
%by this to get a coordinate in axes units
pixperunit = figwidth*(xMaxAxesRat-xMinAxesRat)/100;
offset = xMinAxesRat*figwidth;
ratio = 1/(1+xMinAxesRat);
mousePos = get(0,'PointerLocation');
mouseXPos = mousePos(1);
CinUnits = (mouseXPos-offset)/pixperunit*ratio;
%not perfect, but fairly accurate
%well....it actually ONLY works when the figwindow is half the
%screen...ugh...might have to settle for now

%% INITIALIZE

%GLOBALIZE
global BlockCenter dBlockCenter bwidth

%SIGNAL VARIABLES
stop = 0; %represents whether game continues or not
canShift = 1; %represents whether shift can be done
auto = 1; %control mode #1 
mouse = 2; %control mode #2
keys = 3; %control mode #3
mode = mouse; %represents which control mode is active

%TIME DATA
t = 0; %time variable
p = 0.015; %pause variable
n = 0; %number of iterations counter

%COLOR DATA
darkred = [0.8,0,0];
brightred = [1,0,0];
lightgray = [0.8,0.8,0.825]; %with subtle blue tint
gold = [1,0.85,0];
black = [0,0,0];
white = [1,1,1];
brightblue = [0,0,1];
brightgreen = [0,1,0];
darkgreen = [0,0.5,0];
BasicBrickColor = brightred;
StrongBrickColor = darkred;
SteelBrickColor = lightgray;

%BRICK DATA
numBricksAcross = 7;
numBricksDown = 5;
brickWidth = 100/numBricksAcross; %width of bricks(DEPENDENT)
brickDepth = 8.75; %depth of bricks (MANUAL)
%Coords for regular bricks
brickXCoords = [0,brickWidth,brickWidth,0];
brickYCoords = [0,0,brickDepth,brickDepth];
shift = 0; %initial shift
dshift = -1; %change in shift after each block hit
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
Basic = 1;
Strong = 2;
StrongCracked = 3;
Boom = 4;
Steel = 5;
%Create initial brick patches
for r = 1:numBricksDown
    for c = 1:numBricksAcross
    brickCornerXPos(r,c) = brickWidth*(c-1);
    brickCornerYPos(r,c) = 100-brickDepth*r+shift;
    %Create "original" variable for brickCornerYPos
    brickCornerYPos_org(r,c) = 100-brickDepth*r; %no shift in this array
    bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),StrongBrickColor);
    bricksStatus(r,c) = 1;
    end
end

%BALL DATA
minX = 0;
maxX = 100;
minY = 0;
maxY = 100;
BallVel = 0.75*[1,1]; %velocity vector of ball
markersize = 50; %size of Ball
BallRad = markersize/35; %radius of Ball
rnumX = round(100-2*BallRad); %upper limit of randomized ball coordinate
rnumY = rnumX-round(numBricksDown*brickDepth);
BallPos = [BallRad+randi(rnumX),BallRad+randi(rnumY)];
BallPos0 = BallPos; %saves initial position, helps with debugging
Ball = line(BallPos(1),BallPos(2),'marker','.',...
    'markersize',markersize,'color',white);
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
bwidth = 15; %width of Block
bwidthpixels = bwidth*pixperunit; %width in pixels
dBlockCenter = 10; %change in position when button is pressed
rnum = round(100-bwidth/2);
linewidth = 6; %width of pongBlock
BlockThickness = linewidth/9.5; %thickness of Block                      
BlockCenter = bwidth/2+randi(rnum); %center of position of Block
Block = line([BlockCenter-bwidth/2,BlockCenter+bwidth/2],...
    [0 0],'linewidth',linewidth,'color',brightgreen);

%% LEVEL SETUP
%Change structure of brick grid
yes = 0;
if yes == 1;
%Change brick type in areas of bricks
for c = 1:numBricksAcross
    for r = 1:numBricksDown
        %delete initial brick patch
            delete(bricks(r,c))
            %change color of all brick patches to show brick type
            bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                         brickYCoords+brickCornerYPos(r,c),StrongBrickColor);
            %label brick Type
            bricksStatus(r,c) = Strong;
    end
end
for c = 1:numBricksAcross
    if c/2 == round(c/2)
        for r = 1:numBricksDown
            if r ~= 1 && r ~= numBricksDown
            %delete initial brick patch
%            delete(bricks(r,c))
            %change color of all brick patches to show brick type
%            bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
%                         brickYCoords+brickCornerYPos(r,c),SteelBrickColor);
            %label brick Type
%            bricksStatus(r,c) = Steel;
            end
        end
    end
end
for c = 1:numBricksAcross
    if c == 1 || c == numBricksAcross
        for r = 1:numBricksDown
            %if r ~= 1 && r ~= numBricksDown
            %delete initial brick patch
            delete(bricks(r,c))
            %change color of all brick patches to show brick type
            bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                         brickYCoords+brickCornerYPos(r,c),BasicBrickColor);
            %label brick Type
            bricksStatus(r,c) = Basic;
            %end
        end
    elseif c == 2 || c == numBricksAcross-1
        for r = 2:numBricksDown
        %delete initial brick patch
            delete(bricks(r,c))
            %change color of all brick patches to show brick type
            bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                         brickYCoords+brickCornerYPos(r,c),SteelBrickColor);
            %label brick Type
            bricksStatus(r,c) = Steel;
        end
    end
end

r = numBricksDown
for c = 2:numBricksAcross-1
    %delete initial brick patch
    delete(bricks(r,c))
    %change color of all brick patches to show brick type
    bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                 brickYCoords+brickCornerYPos(r,c),SteelBrickColor);
    %label brick Type
    bricksStatus(r,c) = Steel;
end
%Delete areas of bricks
for n = 1:numBricksDown
    %Rightmost column
%    bricksStatus(n,numBricksAcross) = 0;
%    delete(bricks(n,numBricksAcross))
    %Leftmost column
%    bricksStatus(n,1) = 0;
%    delete(bricks(n,1))
 
    %2nd to last column on right
%    bricksStatus(n,numBricksAcross-1) = 0;
%    delete(bricks(n,numBricksAcross-1))
    %bottommost row
%    bricksStatus(numBricksDown,n) = 0;
%    delete(bricks(numBricksDown,n))
end

end

%Strong bricks only
for c = 1:numBricksAcross
    for r = 1:numBricksDown
        %delete initial brick patch
            delete(bricks(r,c))
            %change color of all brick patches to show brick type
            bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                         brickYCoords+brickCornerYPos(r,c),StrongBrickColor);
            %label brick Type
            bricksStatus(r,c) = Strong;
    end
end
%% LOOP

%Initial Calculations
    %Calculate "horizontal section" and "vertical section," using function
    [vertSect,horSect] = locateBall(BallPos,...
    numBricksAcross,numBricksDown,vertBricksLeft,brickCornerXPos,...
    brickCornerYPos,brickDepth,brickWidth,shift);
    %Calculate borders
    [minX,maxX,minY,maxY] = calcBorders(BallPos,numBricksAcross,...
    numBricksDown,brickWidth,brickDepth,bricksStatus,brickCornerXPos,...
    brickCornerYPos,maxY,vertSect,horSect,shift);

while stop ~= 1
    
    %Update numBricksDown
    [numBricksDown] = update_numBricksDown(numBricksDown,...
    numBricksAcross,bricksStatus);
    
%Check for conditions
if BallPos(2) < 100-brickDepth*numBricksDown+shift %ball is beneath bricks
    %change direction if ball is too far left or right
    %switch to right
    if BallPos(1)-BallRad < 0
        BallVel(1) = -BallVel(1);
        xDirection = right;
    %switch to left
    elseif BallPos(1)+BallRad > 100
        BallVel(1) = -BallVel(1);
        xDirection = left;
    end
    %change direction if ball is too high
    if BallPos(2)+BallRad > maxY
        BallVel(2) = -BallVel(2);
        change = inY;
        [bricksStatus,bricks] = brickReact(numBricksDown,...
        horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
        StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
        crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
        up,down,left,right,change,inX,inY,Steel);
        yDirection = down;
    end
    %check whether block is underneath ball
    if BallPos(2)-BallRad-BlockThickness < 0
        if abs(BallPos(1) - BlockCenter) < bwidth/2
            BallVel(2) = - BallVel(2);
            
            
            
            %I FORGOT, THE VELOCITIES CAN BE NEGATIVE...I HAVE TO CHANGE
            %THE FORMULA BECAUSE THERE IS A SQUARE ROOT
            %Ball Velocity
%            dVx = (BallVel(1)-BlockCenter)*0.8/(bwidth/2); %incremental change in
            %x-velocity depending on block position during collision
%            dVy = sqrt(2-(1+dVx)^2)-1; %conserve total kinetic energy
%            BallVel(1) = BallVel(1)+dVx; %change x-velocity
%            BallVel(2) = BallVel(2)+dVy; %change y-velocity
            yDirection = up;
            %Output for debugging
%            BallVel
            
            
            
           %Shift bricks down
           if canShift == 1 %bricks can be shifted
            [bricks,brickCornerYPos,shift,stop] = shiftBricks(numBricksDown,...
            numBricksAcross,brickCornerYPos_org,bricksStatus,Basic,...
            Strong,Boom,Steel,brickXCoords,brickYCoords,brickCornerXPos,...
            brickCornerYPos,crackedbrickXCoords,crackedbrickYCoords,...
            shift,bricks,StrongCracked,dshift,stop,BlockThickness);
           end
        else
            stop = 1;
        end
    end
elseif BallPos(2) > 100+shift %ball is above bricks
    %switch to right
    if BallPos(1)-BallRad < minX
        BallVel(1) = -BallVel(1);
        xDirection = right;
    end
    %switch to left
    if BallPos(1)+BallRad > maxX
        BallVel(1) = -BallVel(1);
        xDirection = left;
    end
    %switch to down
    if BallPos(2)+BallRad > maxY
        BallVel(2) = -BallVel(2);
        yDirection = down;
    end
    %switch to up
    if BallPos(2)-BallRad < minY
        BallVel(2) = -BallVel(2);
        change = inY;
        [bricksStatus,bricks] = brickReact(numBricksDown,...
        horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
        StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
        crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
        up,down,left,right,change,inX,inY,Steel);
        yDirection = up;
    end
else %ball is within bricks
    %switch to left
    if BallPos(1)+BallRad > maxX
        BallVel(1) = -BallVel(1);
        change = inX;
        if vertSect ~= numBricksAcross %ball is not at rightmost "vertical section"  
            [bricksStatus,bricks] = brickReact(numBricksDown,...
            horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
            StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
            crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
            up,down,left,right,change,inX,inY,Steel);
        end
        xDirection = left;
    end
    %switch to right
    if BallPos(1)-BallRad < minX
        BallVel(1) = -BallVel(1);
        change = inX;
        if vertSect ~= 1 %ball is not at leftmost "vertical section"
            [bricksStatus,bricks] = brickReact(numBricksDown,...
            horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
            StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
            crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
            up,down,left,right,change,inX,inY,Steel);
        end
        xDirection = right;
    end
    %switch to down
    if BallPos(2)+BallRad > maxY
        BallVel(2) = -BallVel(2);
        change = inY;
        if horSect ~= 1 && horSect ~= 0 %ball is not at top "horizontal
            %section" nor above bricks
            %Let brick react
            [bricksStatus,bricks] = brickReact(numBricksDown,...
            horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
            StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
            crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
            up,down,left,right,change,inX,inY,Steel);
        end
        yDirection = down;
    end
    %switch to up
    if BallPos(2)-BallRad < minY
        if minY == 0 %min is the block, not a brick
            %check whether block is underneath ball
            if BallPos(2)-BallRad-BlockThickness < 0
                if abs(BallPos(1) - BlockCenter) < bwidth/2
                    BallVel(2) = - BallVel(2);
                    yDirection = up;
                    %Shift bricks down
                    [bricks,brickCornerYPos,shift,stop] = shiftBricks(numBricksDown,...
                    numBricksAcross,brickCornerYPos_org,bricksStatus,Basic,...
                    Strong,Boom,Steel,brickXCoords,brickYCoords,brickCornerXPos,...
                    brickCornerYPos,crackedbrickXCoords,crackedbrickYCoords,...
                    shift,bricks,StrongCracked,dshift,stop,BlockThickness);
                else
                    stop = 1;
                end
            end
        else %min is a brick
            BallVel(2) = -BallVel(2);
            change = inY;
            if horSect ~= numBricksDown %ball is not at bottommost "horizontal
                                        %section"
                [bricksStatus,bricks] = brickReact(numBricksDown,...
                horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
                StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
                crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
                up,down,left,right,change,inX,inY,Steel);
            end
        end
        yDirection = up;
    end
end

%check for corner scenario
if horSect ~= 0 && horSect < numBricksDown+1 %ball is within bricks
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
        end
        %Change velocities and directions
        BallVel(1) = -BallVel(1);
        BallVel(2) = -BallVel(2);
        xDirection = -xDirection;
        yDirection = -yDirection;
    end
end
    
    %Update ball's position
    BallPos = BallPos+BallVel;
    set(Ball,'XData',BallPos(1),...
                 'YData',BallPos(2));

%AUTO BLOCK
if mode == auto
    BlockCenter = BallPos(1);
    set(Block,'XData',...
        [BlockCenter-bwidth/2,BlockCenter+bwidth/2]);
elseif mode == mouse
    %Use function to update block position
    [BlockCenter,Block] = updateBlockPos(BlockCenter,bwidth,...
    offset,pixperunit,ratio,Block);
elseif mode == keys
    %Allow keyboard function to update block position
    set(Block,'XData',...
        [BlockCenter-bwidth/2,BlockCenter+bwidth/2]);
end

    %Speed change
    [BallVel] = speedChange(BallVel,n,p);
    
    %Update time and counter
    pause(p);
    t = t+p;
    n = n+1;
    
    %Calculate "horizontal section" and "vertical section," using function
    [vertSect,horSect] = locateBall(BallPos,...
    numBricksAcross,numBricksDown,vertBricksLeft,brickCornerXPos,...
    brickCornerYPos,brickDepth,brickWidth,shift);
    
    %Calculate borders
    [minX,maxX,minY,maxY] = calcBorders(BallPos,numBricksAcross,...
    numBricksDown,brickWidth,brickDepth,bricksStatus,brickCornerXPos,...
    brickCornerYPos,maxY,vertSect,horSect,shift);
end

%% FUNCTIONS

function keyboardFunction(figure,event)
global BlockCenter dBlockCenter bwidth
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
end
end

function [BlockCenter,Block] = updateBlockPos(BlockCenter,bwidth,...
    offset,pixperunit,ratio,Block)
%Block Position
mousePos = get(0,'PointerLocation'); %gets pointer coordinates in pixels
mouseXPos = mousePos(1); %x coordinate of pointer
PosInUnits = (mouseXPos-offset)/pixperunit*ratio; %Convert to graph units
if PosInUnits > 0+bwidth/2 && PosInUnits < 100-bwidth/2 %mouse in between
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
    brickCornerYPos,maxY,vertSect,horSect,shift)
%These are the values for below the bricks and they don't matter for above
%the bricks, but need to be here so they can be "outputted"
%Calc minX
minX = 0;
%Calc maxX
maxX = 100;
%Calc minY
minY = 0;
%Calc maxY
maxY = 100; %in case there are no bricks on the lowest level to start
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
end

function [bricksStatus,bricks] = brickReact(numBricksDown,...
    horSect,vertSect,bricksStatus,bricks,StrongBrickColor,Basic,...
    StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
    crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
    up,down,left,right,change,inX,inY,Steel)
if horSect == numBricksDown+1 %ball is below bricks
    r = numBricksDown;
    c = vertSect;
elseif horSect == 0 %ball is above bricks
    r = horSect+1;
    c = vertSect;
else %ball is within bricks
    if change == inY
        if yDirection == up %ball is moving up
            r = horSect-1;
            c = vertSect;
        elseif yDirection == down %ball is moving down
            r = horSect+1;
            c = vertSect;
        end
    elseif change == inX
        if xDirection == right %ball is moving right
            r = horSect;
            c = vertSect+1;
        elseif xDirection == left %ball is moving left
            r = horSect;
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
    elseif bricksStatus(r,c) == Boom
    elseif bricksStatus(r,c) == Steel
        %Brick is not deleted
    end
%Placeholder outputs incase nothing is changed in either of the arrays
bricksStatus;
bricks;
end

function [bricks,brickCornerYPos,shift,stop] = shiftBricks(numBricksDown,...
            numBricksAcross,brickCornerYPos_org,bricksStatus,Basic,...
            Strong,Boom,Steel,brickXCoords,brickYCoords,brickCornerXPos,...
            brickCornerYPos,crackedbrickXCoords,crackedbrickYCoords,...
            shift,bricks,StrongCracked,dshift,stop,BlockThickness)
shift = shift+dshift; %change shift  
for r = 1:numBricksDown
    for c = 1:numBricksAcross
        brickCornerYPos(r,c) = brickCornerYPos_org(r,c)+shift; %Update coords
        if bricksStatus(r,c) ~= 0
            if bricksStatus(r,c) == Basic ||...
               bricksStatus(r,c) == Strong ||...
               bricksStatus(r,c) == Steel
                set(bricks(r,c),'XData',brickXCoords+...
                brickCornerXPos(r,c),'YData',brickYCoords+...
                brickCornerYPos(r,c))
            elseif bricksStatus(r,c) == StrongCracked
                set(bricks(r,c),'XData',crackedbrickXCoords+...
                brickCornerXPos(r,c),'YData',...
                crackedbrickYCoords+brickCornerYPos(r,c))
            elseif bricksStatus(r,c) == Boom
            end
        end
    end
end

%Check if bricks have shifted too low
if brickCornerYPos(numBricksDown,1) <= 0+BlockThickness
    stop = 1; %bricks are too low, change stop
else
    stop; %stop remains unchanged
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

function [BallVel] = speedChange(BallVel,n,p)
dBallVel = 0.05;
%Increase speed incrementally for difficulty
    if n == 7.5/p || n == 15/p || n == 22.5/p || n == 30/p ||...
       n == 37.5/p || n == 45/p || n == 52.5/p || n == 60/p ||...
       n == 67.5/p || n == 75/p
        if BallVel(1) > 0
            BallVel(1) = BallVel(1)+dBallVel;
        else
            BallVel(1) = BallVel(1)-dBallVel;
        end
        if BallVel(2) > 0
            BallVel(2) = BallVel(2)+dBallVel;
        else
            BallVel(2) = BallVel(2)-dBallVel;
        end
    end 
BallVel;    
end
