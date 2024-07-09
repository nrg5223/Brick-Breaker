%game_brickwalls
clear
clc

%IDEAS/NOTES
% - make main menu screen and start button
% - make adjustable sensitivities
% - use mouse input instead of keys (maybe include both options)
% - make it like the game with the blocks on the top of the screen that you
%   have to destroy
% - implement conservation of momentum into physics to make it more
%   realistic and interesting

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
%'color','black',
    %'XTickLabels',[],'YTickLabels',[],...
brickwallsAxes = axes('XLim',[0 100],'YLim',[-5 100],...
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

%BRICK DATA
numBricksAcross = 5;
numBricksDown = 3;
brickWidth = 100/numBricksAcross; %width of bricks(DEPENDENT)
brickDepth = 10; %depth of bricks (MANUAL)
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
    end
end
%brickCornerPos = [brickCornerXPos;brickCornerYPos]; %array containing
%coordinates of bottom-left corners of all bricks
for n = 1:numBricks
%   bricks(x,y) = patch(brickXCoords+brickCornerXPos(n),...
%                     brickYCoords+brickCornerYPos(n),'r');
end
vertBricksLeft = numBricksDown; %represents number of bricks left
                               %in "vertical section"
for n = 2:numBricksAcross
vertBricksLeft = [vertBricksLeft,numBricksDown]; %"add" another element
end

%BALL DATA
BallVel = [1,1]; %velocity vector of ball
markersize = 50; %size of Ball
BallRad = markersize/35; %radius of Ball
rnumX = round(100-2*BallRad); %upper limit of randomized ball coordinate
rnumY = rnumX-round(numBricksDown*brickDepth);
BallPos = [BallRad+randi(rnumX),BallRad+randi(rnumY)];
Ball = line(BallPos(1),BallPos(2),'marker','.',...
    'markersize',markersize,'color','red');

%BLOCK DATA
bwidth = 15; %width of pongBlock
dBlockCenter = 10; %change in position when button is pressed
rnum = round(100-bwidth/2);
linewidth = 5; %width of pongBlock
BlockThickness = linewidth/9.5; %thickness of pongBlock                      
BlockCenter = bwidth/2+randi(rnum); %center of position of PongBlock
Block = line([BlockCenter-bwidth/2,BlockCenter+bwidth/2],...
    [0 0],'linewidth',linewidth,'color','green');

%SCRAPPED
%BallMass = 1; %not sure what value or units to give this
%BlockMass = 1; %not sure what value or units to give this
%BlockRad = BlockThickness/2; %"radius" of the block (distance from center
%                             %to edge)
%BlockY = 0; %y-position of block
%BlockVel = [-1,0]; %velocity vector of block

%% LOOP

while stop ~= 1
    %Calculate max height, maxHeight and 
    %"vertical section," vertSect using function
    [maxHeight,vertSect] = calc_maxH(BallPos,numBricksAcross,...
        vertBricksLeft,brickCornerXPos,brickDepth,brickWidth);
    
    %Change direction if ball is too far left or right
    if BallPos(1)-BallRad < 0 || BallPos(1)+BallRad > 100
        BallVel(1) = -BallVel(1);
    end
    %change direction if ball hits bottom of brick
    if BallPos(2)+BallRad > maxHeight
        BallVel(2) = -BallVel(2);
        if vertBricksLeft(vertSect) > 0
        delete(bricks(vertBricksLeft(vertSect),vertSect))
        vertBricksLeft(vertSect) = vertBricksLeft(vertSect)-1;
        end
    end
    %change direction if ball hits top of brick
    
    %check whether block is underneath ball
    if BallPos(2)-BallRad-BlockThickness < 0
        if abs(BallPos(1) - BlockCenter) < bwidth/2
            BallVel(2) = - BallVel(2);
        else
            stop = 1;
        end
    end
    
    %Update ball's position
    BallPos = BallPos+BallVel;
    set(Ball,'XData',BallPos(1),...
                 'YData',BallPos(2));
    
%AUTO BLOCK
BlockCenter = BallPos(1);
             
    %Update block's position
    set(Block,'XData',...
        [BlockCenter-bwidth/2,BlockCenter+bwidth/2]);
    
    %Update time
    pause(p);
    t = t+p;
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

function [maxHeight,vertSect] = calc_maxH(BallPos,numBricksAcross,...
    vertBricksLeft,brickCornerXPos,brickDepth,brickWidth)
n = 1;

%DID NOT WORK, BUT KEEPING IT IN CASE IT CAN BE USED IN THE FUTURE
%while BallPos(1) > brickCornerXPos(n)
%        a = n;
%    n = n+1;

for n = 1:numBricksAcross
    %Check which "vertical section" of bricks the ball is
    %underneath (x-position)
    x = BallPos(1) - brickCornerXPos(1,n);
    if x < brickWidth && x > 0
        S = n;
    end
    n = n+1;
end
maxHeight = 100-vertBricksLeft(S)*brickDepth; %height of lowest brick in
                                             %ball's "vertical section"
vertSect = S; %"vertical section" of ball
end
