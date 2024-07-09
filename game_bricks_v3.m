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
% - bricks shift down after the ball hits the blocker

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

%TIME DATA
t = 0; %time variable
p = 0.015; %pause variable
n = 0; %number of iterations counter

%BRICK DATA
numBricksAcross = 7;
numBricksDown = 5;
brickWidth = 100/numBricksAcross; %width of bricks(DEPENDENT)
brickDepth = 8.75; %depth of bricks (MANUAL)
brickXCoords = [0,brickWidth,brickWidth,0];
brickYCoords = [0,0,brickDepth,brickDepth];
numBricks = numBricksAcross*numBricksDown; %number of bricks (10 x 4 grid)
n = 1; %counter
for y = 1:numBricksDown
    for x = 1:numBricksAcross
    brickCornerXPos(y,x) = brickWidth*(x-1);
    brickCornerYPos(y,x) = 100-brickDepth*y;
    %n = n+1;
    bricks(y,x) = patch(brickXCoords+brickCornerXPos(y,x),...
                     brickYCoords+brickCornerYPos(y,x),'r');
    bricksExist(y,x) = 1;
    end
end

vertBricksLeft = numBricksDown; %represents number of bricks left
                               %in "vertical section"
for n = 2:numBricksAcross
vertBricksLeft = [vertBricksLeft,numBricksDown]; %"add" another element
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
BallPos = [80,30];
BallPos0 = BallPos; %saves initial position, helps with debugging
Ball = line(BallPos(1),BallPos(2),'marker','.',...
    'markersize',markersize,'color','white');

%BLOCK DATA
bwidth = 20; %width of pongBlock
dBlockCenter = 10; %change in position when button is pressed
rnum = round(100-bwidth/2);
linewidth = 6; %width of pongBlock
BlockThickness = linewidth/9.5; %thickness of Block                      
BlockCenter = bwidth/2+randi(rnum); %center of position of Block
Block = line([BlockCenter-bwidth/2,BlockCenter+bwidth/2],...
    [0 0],'linewidth',linewidth,'color','green');

%SCRAPPED
%brickCornerPos = [brickCornerXPos;brickCornerYPos]; %array containing
%coordinates of bottom-left corners of all bricks
for n = 1:numBricks
%   bricks(x,y) = patch(brickXCoords+brickCornerXPos(n),...
%                     brickYCoords+brickCornerYPos(n),'r');
end
for y = 1:numBricksDown
    for x = 1:numBricksAcross
    %locateBall(y,x) = 0; %shows section of area in brick grid in which ball
    %currently exists
    end
end

%% LOOP

%FOR DEBUGGING - deletes outside columns (could be used in a level)
for n = 1:numBricksDown
    %Rightmost column
    bricksExist(n,numBricksAcross) = 0;
    delete(bricks(n,numBricksAcross))
    %Leftmost column
    bricksExist(n,1) = 0;
    delete(bricks(n,1))
end
for n = 2:numBricksAcross-1
    %Topmost row
    bricksExist(1,n) = 0;
    delete(bricks(1,n))
end

while stop ~= 1
    %Calculate "horizontal section" and "vertical section," using function
    [vertSect,horSect] = locateBall(BallPos,...
    numBricksAcross,numBricksDown,vertBricksLeft,brickCornerXPos,...
    brickCornerYPos,brickDepth,brickWidth);

    %Calculate borders
    [minX,maxX,minY,maxY] = calcBorders(BallPos,numBricksAcross,...
    numBricksDown,brickWidth,brickDepth,bricksExist,brickCornerXPos,...
    brickCornerYPos,maxY,vertSect,horSect);

if horSect == 0 %ball is beneath bricks, different conditionals
    %change direction if ball is too far left or right
    if BallPos(1)-BallRad < 0 || BallPos(1)+BallRad > 100
        BallVel(1) = -BallVel(1);
    end
    %change direction if ball is too high
    if BallPos(2)+BallRad > maxY
        BallVel(2) = -BallVel(2);
        bricksExist(numBricksDown,vertSect) = 0;
        delete(bricks(numBricksDown,vertSect));
    end
    %check whether block is underneath ball
    if BallPos(2)-BallRad-BlockThickness < 0
        if abs(BallPos(1) - BlockCenter) < bwidth/2
            BallVel(2) = - BallVel(2);
        else
            stop = 1;
        end
    end
else %ball is above bricks, different conditionals
    %switch to right
    if BallPos(1)+BallRad > maxX
        BallVel(1) = -BallVel(1);
        if vertSect ~= numBricksAcross %ball is not at rightmost "vertical section"  
            if bricksExist(horSect,vertSect+1) == 1 %brick exists
            bricksExist(horSect,vertSect+1) = 0;
            delete(bricks(horSect,vertSect+1));
            end
        end
    end
    %switch to left
    if BallPos(1)-BallRad < minX
        BallVel(1) = -BallVel(1);
        if vertSect ~= 1 %ball is not at leftmost "vertical section"
            if bricksExist(horSect,vertSect-1) == 1 %brick exists
            bricksExist(horSect,vertSect-1) = 0;
            delete(bricks(horSect,vertSect-1));
            end
        end
    end
    %switch to down
    if BallPos(2)+BallRad > maxY
        BallVel(2) = -BallVel(2);
        if horSect ~= 1 %ball is not at top "horizontal section"
            if bricksExist(horSect-1,vertSect) == 1 %brick exists
            bricksExist(horSect-1,vertSect) = 0;
            delete(bricks(horSect-1,vertSect));
            end
        end
    end
    %switch to up
    if BallPos(2)-BallRad < minY
        BallVel(2) = -BallVel(2);
        if horSect ~= numBricksDown %ball is not at bottommost "horizontal
                                    %section"
            if bricksExist(horSect+1,vertSect) == 1 %brick exists
            bricksExist(horSect+1,vertSect) = 0;
            delete(bricks(horSect+1,vertSect));
            end
        end
    end
end

%check for corner bug
if horSect ~= 0 %ball is above bricks
    if bricksExist(horSect,vertSect) == 1 %ball is inside of a brick
        BallVel = -BallVel; %reverse velocity to bounce off the corner
        bricksExist(horSect,vertSect) = 0;
        delete(bricks(horSect,vertSect))
    end
end
    
    %Update ball's position
    BallPos = BallPos+BallVel;
    set(Ball,'XData',BallPos(1),...
                 'YData',BallPos(2));
    
    %Update block's position
    set(Block,'XData',...
        [BlockCenter-bwidth/2,BlockCenter+bwidth/2]);
    
    %Increase speed incrementally for difficulty
    if n == 7.5/p || n == 15/p || n == 22.5/p || n == 30/p ||...
       n == 37.5/p || n == 45/p || n == 52.5/p || n == 60/p ||...
       n == 67.5/p || n == 75/p
        if BallVel(1) > 0
            BallVel(1) = BallVel(1)+0.05
        else
            BallVel(1) = BallVel(1)-0.05
        end
        if BallVel(2) > 0
            BallVel(2) = BallVel(2)+0.05
        else
            BallVel(2) = BallVel(2)-0.05
        end
    end
    
    %Update time and counter
    pause(p);
    t = t+p;
    n = n+1;
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
    brickCornerYPos,brickDepth,brickWidth)

%Calculate "vertical section" of ball (x-position)
for n = 1:numBricksAcross
    x = BallPos(1) - brickCornerXPos(1,n);
    if x < brickWidth && x > 0
        vertSect = n;
    end
end

%Calculate "horizontal section" of ball (y-position)
horSect = 0; %placeholder in case condition isn't met
if BallPos(2) > 100-numBricksDown*brickDepth
    for n = 1:numBricksDown
        x = BallPos(2) - brickCornerYPos(n,1);
        if x < brickDepth && x > 0
            horSect = n;
        end
    end
    
end

end

function [minX,maxX,minY,maxY] = calcBorders(BallPos,numBricksAcross,...
    numBricksDown,brickWidth,brickDepth,bricksExist,brickCornerXPos,...
    brickCornerYPos,maxY,vertSect,horSect)
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
if horSect == 0 %Ball is below bricks
    %Calc maxY
    for n = 1:numBricksDown
        if bricksExist(n,vertSect) == 1
           maxY = 100-n*brickDepth;
        end
    end
else %ball is above bricks
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
