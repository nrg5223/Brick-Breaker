%game_brickwalls
clear
clc
close all

%IDEAS/NOTES
% - make main menu screen and start button
% - make adjustable sensitivities
% - use mouse input instead of keys (maybe include both options)
% - implement conservation of momentum into physics to make it more
%   realistic and interesting
% - different levels (5 or 10 depending on how much I care...probably 5)
% - have the unbreakable sections of wall on some levels
% - different color bricks with different strengths (some need to be hit
%   different number of times to be broken
% - GOLDEN BRICK: when destroyed, explodes and destroys the surrounding
%   bricks
% - power ups (maybe): longer block (change bwidth and color of block),
% exploding or enlarged ball, decrease ball speed, reset brick position to
% top, ball explodes into multiple smaller balls (either smaller ones of a
% different color that cannot be controlled/hit or multiple balls identical
% to the regular one which may all be controlled/hit,
% wrecking ball that goes through a line of bricks, laser ability that lets
% user push space bar to shoot laser towards bricks

%% SETUP

%Get screensize
screensize = get(0,'ScreenSize');
figwidth = screensize(3)/2;
figheight = screensize(4)-120;

%Create blue figure that has a KeyPressFcn with a function handle
%keyboardFunction
brickwallsFigure = figure('Position',[0,40,figwidth,figheight],...
    'color','blue','KeyPressFcn',@keyboardFunction);

%Create axes
brickwallsAxes = axes('XLim',[0 100],'YLim',[-5 100],...
    'color','black',...
    'XTickLabels',[],'YTickLabels',[],...
    'position',[0.05,0.05,0.9,0.9]);
grid on

%% INITIALIZE

%GLOBALIZE
global BlockCenter dBlockCenter bwidth

%SIGNAL VARIABLES
stop = 0; %represents whether game continues or not
auto_on = 1; %represents whether auto mode is on or not

%TIME DATA
t = 0; %time variable
p = 0.015; %pause variable
n = 0; %number of iterations counter

%COLOR DATA
darkred = [0.8,0,0];
brightred = [1,0,0];
lightgray = [0.8,0.8,0.8];
gold = [1,0.85,0];
black = [0,0,0];
white = [1,1,1];
brightblue = [0,0,1];
brightgreen = [0,1,0];

%BRICK DATA
shift = 0; %initial shift
dshift = -1; %change in shift after each block hit
numBricksAcross = 7;
numBricksDown = 5;
brickWidth = 100/numBricksAcross; %width of bricks(DEPENDENT)
brickDepth = 8.75; %depth of bricks (MANUAL)
%Coords for regular bricks
brickXCoords = [0,brickWidth,brickWidth,0];
brickYCoords = [0,0,brickDepth,brickDepth];

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
%Create initial brick patches
for r = 1:numBricksDown
    for c = 1:numBricksAcross
    brickCornerXPos(r,c) = brickWidth*(c-1);
    brickCornerYPos(r,c) = 100-brickDepth*r+shift;
    %Create "original" variable for brickCornerYPos
    brickCornerYPos_org(r,c) = 100-brickDepth*r; %no shift in this array
    bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                     brickYCoords+brickCornerYPos(r,c),brightred);
    bricksExist(r,c) = 1;
    bricksType(r,c) = 1;
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
%For corner scenario
%BallPos = [(numBricksAcross-1)*brickWidth+10,...
%    100-numBricksDown*brickDepth-2*brickWidth+1+10];
%BallPos = [(numBricksAcross-2)*brickWidth+10,...
%    100-numBricksDown*brickDepth-3.4*brickWidth+1+10]
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
bwidth = 20; %width of pongBlock
dBlockCenter = 10; %change in position when button is pressed
rnum = round(100-bwidth/2);
linewidth = 6; %width of pongBlock
BlockThickness = linewidth/9.5; %thickness of Block                      
BlockCenter = bwidth/2+randi(rnum); %center of position of Block
Block = line([BlockCenter-bwidth/2,BlockCenter+bwidth/2],...
    [0 0],'linewidth',linewidth,'color',brightgreen);

%% LEVEL SETUP
%Change structure of brick grid
yes = 1;
if yes == 1;
%Change brick type for areas of bricks
for r = 1:numBricksDown
    if r/2 == round(r/2)
        for c = 1:numBricksAcross
            %delete initial brick patch
            delete(bricks(r,c))
            %change color of all brick patches to show brick type
            bricks(r,c) = patch(brickXCoords+brickCornerXPos(r,c),...
                         brickYCoords+brickCornerYPos(r,c),darkred);
            %label brick Type
            bricksType(r,c) = Strong;
        end
    end
end
end

%Delete areas of bricks
for n = 1:numBricksDown
    %Rightmost column
%    bricksExist(n,numBricksAcross) = 0;
%    delete(bricks(n,numBricksAcross))
    %Leftmost column
%    bricksExist(n,1) = 0;
%    delete(bricks(n,1))
 
    %2nd to last column on right
%    bricksExist(n,numBricksAcross-1) = 0;
%    delete(bricks(n,numBricksAcross-1))
    %bottommost row
%    bricksExist(numBricksDown,n) = 0;
%    delete(bricks(numBricksDown,n))
end

%% LOOP

%Initial Calculations
    %Calculate "horizontal section" and "vertical section," using function
    [vertSect,horSect] = locateBall(BallPos,...
    numBricksAcross,numBricksDown,vertBricksLeft,brickCornerXPos,...
    brickCornerYPos,brickDepth,brickWidth,shift);
    %Calculate borders
    [minX,maxX,minY,maxY] = calcBorders(BallPos,numBricksAcross,...
    numBricksDown,brickWidth,brickDepth,bricksExist,brickCornerXPos,...
    brickCornerYPos,maxY,vertSect,horSect,shift);

while stop ~= 1
    
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
        [bricksType,bricksExist,bricks] = brickReact(numBricksDown,...
        horSect,vertSect,bricksExist,bricksType,bricks,darkred,Basic,...
        StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
        crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
        up,down,left,right,change,inX,inY);
        yDirection = down;
    end
    %check whether block is underneath ball
    if BallPos(2)-BallRad-BlockThickness < 0
        if abs(BallPos(1) - BlockCenter) < bwidth/2
            BallVel(2) = - BallVel(2);
            yDirection = up;
            shift = shift+dshift; %change shift
            %Shift bricks down
            for r = 1:numBricksDown
                for c = 1:numBricksAcross
                    brickCornerYPos(r,c) =...
                        brickCornerYPos_org(r,c)+shift; %update Coords
                    if bricksExist(r,c) == 1
                        if bricksType(r,c) == Basic ||...
                           bricksType(r,c) == Strong
                            set(bricks(r,c),'XData',brickXCoords+...
                            brickCornerXPos(r,c),'YData',brickYCoords+...
                            brickCornerYPos(r,c));
                        elseif bricksType(r,c) == StrongCracked
                            set(bricks(r,c),'XData',crackedbrickXCoords+...
                            brickCornerXPos(r,c),'YData',...
                            crackedbrickYCoords+brickCornerYPos(r,c));
                        elseif bricksType(r,c) == Boom
                        end
                    end
                end
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
        [bricksType,bricksExist,bricks] = brickReact(numBricksDown,...
        horSect,vertSect,bricksExist,bricksType,bricks,darkred,Basic,...
        StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
        crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
        up,down,left,right,change,inX,inY)
        yDirection = up;
    end
else %ball is within bricks
    %switch to left
    if BallPos(1)+BallRad > maxX
        BallVel(1) = -BallVel(1);
        change = inX;
        if vertSect ~= numBricksAcross %ball is not at rightmost "vertical section"  
            [bricksType,bricksExist,bricks] = brickReact(numBricksDown,...
            horSect,vertSect,bricksExist,bricksType,bricks,darkred,Basic,...
            StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
            crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
            up,down,left,right,change,inX,inY);
        end
        xDirection = left;
    end
    %switch to right
    if BallPos(1)-BallRad < minX
        BallVel(1) = -BallVel(1);
        change = inX;
        if vertSect ~= 1 %ball is not at leftmost "vertical section"
            [bricksType,bricksExist,bricks] = brickReact(numBricksDown,...
            horSect,vertSect,bricksExist,bricksType,bricks,darkred,Basic,...
            StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
            crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
            up,down,left,right,change,inX,inY);
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
            [bricksType,bricksExist,bricks] = brickReact(numBricksDown,...
            horSect,vertSect,bricksExist,bricksType,bricks,darkred,Basic,...
            StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
            crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
            up,down,left,right,change,inX,inY);
        end
        yDirection = down;
    end
    %switch to up
    if BallPos(2)-BallRad < minY
        BallVel(2) = -BallVel(2);
        change = inY;
        if horSect ~= numBricksDown %ball is not at bottommost "horizontal
                                    %section"
            [bricksType,bricksExist,bricks] = brickReact(numBricksDown,...
            horSect,vertSect,bricksExist,bricksType,bricks,darkred,Basic,...
            StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
            crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
            up,down,left,right,change,inX,inY);
        end
        yDirection = up;
    end
end

%check for corner scenario
if horSect ~= 0 && horSect ~= numBricksDown+1 %ball is within bricks
    if bricksExist(horSect,vertSect) == 1 %ball is inside of a brick
        if bricksType(horSect,vertSect) == Basic ||...
           bricksType(horSect,vertSect) == StrongCracked
            %Delete brick
            bricksExist(horSect,vertSect) = 0;
            delete(bricks(horSect,vertSect));
        elseif bricksType(horSect,vertSect) == Strong
            %Crack brick and change brick type
            delete(bricks(horSect,vertSect))
            bricks(horSect,vertSect) = patch(crackedbrickXCoords...
            +brickCornerXPos(horSect,vertSect),...
            crackedbrickYCoords+brickCornerYPos(horSect,vertSect),darkred);
            bricksType(horSect,vertSect) = StrongCracked;
        elseif bricksType(horSect,vertSect) == Boom
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
if auto_on == 1
BlockCenter = BallPos(1);
end

    %Update block's position
    set(Block,'XData',...
        [BlockCenter-bwidth/2,BlockCenter+bwidth/2]);
    
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
    numBricksDown,brickWidth,brickDepth,bricksExist,brickCornerXPos,...
    brickCornerYPos,maxY,vertSect,horSect,shift);
    
bricksType
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

function [vertSect,horSect] = locateBall(BallPos,...
    numBricksAcross,numBricksDown,vertBricksLeft,brickCornerXPos,...
    brickCornerYPos,brickDepth,brickWidth,shift)

%Calculate "vertical section" of ball (x-position)
for n = 1:numBricksAcross
    x = BallPos(1) - brickCornerXPos(1,n);
    if x < brickWidth && x >= 0
        vertSect = n
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
    numBricksDown,brickWidth,brickDepth,bricksExist,brickCornerXPos,...
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
        if bricksExist(n,vertSect) == 1
           maxY = 100-n*brickDepth+shift;
        end
    end
elseif horSect == 0 %ball is above bricks
    minX = 0;
    maxX = 100;
    %Check border brick (brick below ball)
    if bricksExist(horSect+1,vertSect) == 1
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
        if bricksExist(horSect,vertSect+1) == 1
            maxX = brickCornerXPos(horSect,vertSect+1);
        else
            maxX = 100;
        end
        %bottom side (minY)
        if bricksExist(horSect+1,vertSect) == 1
            minY = brickDepth+brickCornerYPos(horSect+1,vertSect);
        else
            minY = 0;
        end
    elseif vertSect == 1 && horSect == numBricksDown %ball is in
                                     %bottom-left corner of brick grid
        %check border bricks
        %right side (maxX)
        if bricksExist(horSect,vertSect+1) == 1
            maxX = brickCornerXPos(horSect,vertSect+1);
        else
            maxX = 100;
        end
        %top side (maxY)
        if bricksExist(horSect-1,vertSect) == 1
            maxY = brickCornerYPos(horSect-1,vertSect);
        else
            maxY = 100;
        end
    elseif vertSect == numBricksAcross && horSect == 1 %ball is in
                                     %top-right corner of brick grid
        %check border bricks
        %left side (minX)
        if bricksExist(horSect,vertSect-1) == 1
            minX = brickWidth+brickCornerXPos(horSect,vertSect-1);
        else
            minX = 0;
        end
        %bottom side (minY)
        if bricksExist(horSect+1,vertSect) == 1
            minY = brickDepth+brickCornerYPos(horSect+1,vertSect);
        else
            minY = 0;
        end
    elseif vertSect == numBricksAcross && horSect == numBricksDown %ball is
                                    %in bottom-right corner of brick grid
        %check border bricks
        %left side (minX)
        if bricksExist(horSect,vertSect-1) == 1
            minX = brickWidth+brickCornerXPos(horSect,vertSect-1);
        else
            minX = 0;
        end
        %top side (maxY)
        if bricksExist(horSect-1,vertSect) == 1
            maxY = brickCornerYPos(horSect-1,vertSect);
        else
            maxY = 100;
        end
    elseif vertSect == 1 %ball is in leftmost "vertical section"
        %check border bricks
        %right side (maxX)
        if bricksExist(horSect,vertSect+1) == 1
            maxX = brickCornerXPos(horSect,vertSect+1);
        else
            maxX = 100;
        end
        %bottom side (minY)
        if bricksExist(horSect+1,vertSect) == 1
            minY = brickDepth+brickCornerYPos(horSect+1,vertSect);
        else
            minY = 0;
        end
        %top side (maxY)
        if bricksExist(horSect-1,vertSect) == 1
            maxY = brickCornerYPos(horSect-1,vertSect);
        else
            maxY = 100;
        end
    elseif vertSect == numBricksAcross %ball is in rightmost "vertical
                                       %section"
        %check border bricks
        %left side (minX)
        if bricksExist(horSect,vertSect-1) == 1
            minX = brickWidth+brickCornerXPos(horSect,vertSect-1);
        else
            minX = 0;
        end
        %bottom side (minY)
        if bricksExist(horSect+1,vertSect) == 1
            minY = brickDepth+brickCornerYPos(horSect+1,vertSect);
        else
            minY = 0;
        end
        %top side (maxY)
        if bricksExist(horSect-1,vertSect) == 1
            maxY = brickCornerYPos(horSect-1,vertSect);
        else
            maxY = 100;
        end
    elseif horSect == 1 %ball is in topmost "horizontal section"
        %check border bricks
        %left side (minX)
        if bricksExist(horSect,vertSect-1) == 1
            minX = brickWidth+brickCornerXPos(horSect,vertSect-1);
        else
            minX = 0;
        end
        %right side (maxX)
        if bricksExist(horSect,vertSect+1) == 1
            maxX = brickCornerXPos(horSect,vertSect+1);
        else
            maxX = 100;
        end
        %bottom side (minY)
        if bricksExist(horSect+1,vertSect) == 1
            minY = brickDepth+brickCornerYPos(horSect+1,vertSect);
        else
            minY = 0;
        end
    elseif horSect == numBricksDown %ball is in bottommost "horiontal
                                    %section"
        %check border bricks
        %left side (minX)
        if bricksExist(horSect,vertSect-1) == 1
            minX = brickWidth+brickCornerXPos(horSect,vertSect-1);
        else
            minX = 0;
        end
        %right side (maxX)
        if bricksExist(horSect,vertSect+1) == 1
            maxX = brickCornerXPos(horSect,vertSect+1);
        else
            maxX = 100;
        end
        %top side (maxY)
        if bricksExist(horSect-1,vertSect) == 1
            maxY = brickCornerYPos(horSect-1,vertSect);
        else
            maxY = 100;
        end
    else %ball is in middle section of bricks
    %Check border bricks
        %left side (minX)
        if bricksExist(horSect,vertSect-1) == 1
            minX = brickWidth+brickCornerXPos(horSect,vertSect-1);
        else
            minX = 0;
        end
        %right side (maxX)
        if bricksExist(horSect,vertSect+1) == 1
            maxX = brickCornerXPos(horSect,vertSect+1);
        else
            maxX = 100;
        end
        %bottom side (minY)
        if bricksExist(horSect+1,vertSect) == 1
            minY = brickDepth+brickCornerYPos(horSect+1,vertSect);
        else
            minY = 0;
        end
        %top side (maxY)
        if bricksExist(horSect-1,vertSect) == 1
            maxY = brickCornerYPos(horSect-1,vertSect);
        else
            maxY = 100;
        end
    end
end
end

function [bricksType,bricksExist,bricks] = brickReact(numBricksDown,...
    horSect,vertSect,bricksExist,bricksType,bricks,darkred,Basic,...
    StrongCracked,Strong,Boom,crackedbrickXCoords,xDirection,...
    crackedbrickYCoords,brickCornerXPos,brickCornerYPos,yDirection,...
    up,down,left,right,change,inX,inY)
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
    if bricksType(r,c) == Basic ||...
       bricksType(r,c) == StrongCracked
        %Delete brick
        bricksExist(r,c) = 0;
        delete(bricks(r,c));
    elseif bricksType(r,c) == Strong
        %Crack brick and change brick type
        delete(bricks(r,c))
        bricks(r,c) = patch(crackedbrickXCoords...
            +brickCornerXPos(r,c),...
            crackedbrickYCoords+brickCornerYPos(r,c),darkred);
            bricksType(r,c) = StrongCracked;
    elseif bricksType(r,c) == Boom
    end
%Placeholder outputs incase nothing is changed in either of the arrays
bricksExist;
bricksType;
bricks;
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
