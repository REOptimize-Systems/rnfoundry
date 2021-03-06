function [xq,yq,zq,C,hc,hax,hfig] = contourf2dtable(x, y, data, varargin)
% creates a filled contour plot of the data in a 2D table
%
% Syntax
%
% contourf2dtable(x, y, data, ...)
%
% Inputs
% 
%  x - vector of values representing the independent variable variables of
%   the rows of the table, must be linearly spaced
%
%  y - vector of values representing the independent variable variables of
%   the columns of the table, must be linearly spaced
%
%  data - (2 x 2) matrix of data containing the dependent variables
%    corresponding to each combination of the independent values provided
%    in the x and y vectors
%
% Examples
%
% x = 1:10
% y = 0.5:0.5:5
% data = bsxfun(@times, x, y')
% contourf2dtable(x, y, data)
%
% See also, mesh
%

% Copyright Richard Crozier 2015

    options.XLabel = '';
    options.YLabel = '';
    options.ZLabel = '';
    options.Title = '';
    options.ContourfArgs = {};
    options.Axes = [];
    
    options = parse_pv_pairs (options, varargin);
    
    [newx, newy, newz] = makevars2dtable23dplot (x, y, data);
    
    % now mesh the data
    [xq,yq] = meshgrid (x,y);
    
    zq = griddata (newx, newy, newz, xq, yq);
    
    if isempty (options.Axes)
        hfig = figure;
        hax = axes;
    else
        hax = options.Axes;
        hfig = get (hax, 'Parent');
    end
    
    % and create the mesh plot
    [C,hc] = contourf(xq,yq,zq, options.ContourfArgs{:});

    if ~isempty (options.XLabel)
        xlabel (options.XLabel);
    end

    if ~isempty (options.XLabel)
        ylabel (options.YLabel);
    end
    
    if ~isempty (options.XLabel)
        zlabel (options.ZLabel);
    end
    
    if ~isempty (options.Title)
        title (options.Title);
    end
    
end