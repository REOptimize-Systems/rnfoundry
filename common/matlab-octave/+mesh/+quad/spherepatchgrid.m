function [vertices, faces, edge_inds] = spherepatchgrid (R, n, varargin)
% creates a quad mesh of a patch on a sphere by projecting a grid onto it
%
% Syntax
%
% [vertices, faces, edge_inds] = cubedspherepatch (R, n)
% [vertices, faces, edge_inds] = cubedspherepatch (..., 'Parameter', Value)
%
% Description
%
% cubedspherepatch creates a quad mesh of the end of a sphere which can
% optionally be clipped above a certain Z or Y position. It works by
% projecting a grid onto the surface of a shere, and is useful for creating
% quadrilateral meshes of spherically curved domains, without degenerate
% quads (i.e triangles).
%
% Input
%
%  R - radius of the sphere end to be meshed
%
%  n - number of faces to produce on the end of the sphere
%
% Addtional arguments may be supplied as parameter-value pairs. The
% available options are:
%
%  'ProjectionType' - character vector indicating the type of projection to
%    use
%
%  'CutZMax' - Cut off any faces which extend higher in Z direction than 
%    the value specified here
%
%  'CutZMin' - Cut off any faces which extend lower in Z direction than 
%    the value specified here
%
%  'CutYMax' - Cut off any faces which extend in positive Y direction more  
%    than the value specified here
%
%  'CutYMin' - Cut off any faces which have vertices with Y positions less  
%    than the value specified here
%
% Output
%
%  vertices - (3 x v) matrix of vertices
%
%  faces - (4 x u) matrix of indices into the vertices matrix where each
%    column represents one face
%
%  edge_inds - vector of indices into the vertices matrix for the points on
%    the outer edge of the generated mesh, these are the points on the
%    outer boundary starting from the the point with the minimum Y position
%    and minimum Z position and moving anti-clockwise around the outer
%    boundary.
%


    options.CutZMax = [];
    options.CutZMin = [];
    options.CutYMax = [];
    options.CutYMin = [];
    
    options.ProjectionType = 'equidistance';
    
    options = parse_pv_pairs (options, varargin);
    
    n = round (n);
    
    if n < 1
        error ('cubedsphere: n must be stricly positive number');
    end
    
    n = n+1;
    
    % Discretize basic face of a cube
    switch lower (options.ProjectionType)
        case 'equiangular'
            % equidistance projection
            x = R;
            theta = linspace (-pi/4, pi/4, n);
            y = tan (theta);
            z = y;
            [X, Y, Z] = ndgrid (x,y,z);
        case 'equidistance'
            % equidistance projection
            x = R;
            y = linspace (-R, R, n);
            z = y;
            [X, Y, Z] = ndgrid (x,y,z);
        otherwise
            error('cubedsphere: ProjectionType must be ''equiangular'' or ''equidistance''');
    end
    
    % Patch topology
    [i, j] = meshgrid (1:n-1,1:n-1); % 090815: Change to meshgrid from ndgrid
    i = i(:); j=j(:);
    faces = [ sub2ind([n n], i, j) ...
              sub2ind([n n], i+1, j) ...
              sub2ind([n n], i+1, j+1) ...
              sub2ind([n n], i, j+1) ].';
         

    X = X(:);
    Y = Y(:);
    Z = Z(:);
    
    remove_face = [];
    if ~isempty (options.CutZMax)
       
        uncut_inds = find (Z <= options.CutZMax);
        
        cut_inds = find (Z > options.CutZMax);
        
        for face_ind = 1:size(faces, 2)
            for vert_ind = 1:4
                if any (faces(vert_ind,face_ind) == cut_inds)
                    remove_face = [remove_face, face_ind];
                end
            end
        end
        
        faces(:,remove_face) = [];
        
        X = X(uncut_inds);
        Y = Y(uncut_inds);
        Z = Z(uncut_inds);
        
    end
    
    if ~isempty (options.CutZMin)
       
        uncut_inds = find (Z >= options.CutZMin);
        
        cut_inds = find (Z < options.CutZMin);
        
        for face_ind = 1:size(faces, 2)
            for vert_ind = 1:4
                if any (faces(vert_ind,face_ind) == cut_inds)
                    remove_face = [remove_face, face_ind];
                end
            end
        end
        
        faces(:,remove_face) = [];
        
        X = X(uncut_inds);
        Y = Y(uncut_inds);
        Z = Z(uncut_inds);
        
    end
    
    if ~isempty (options.CutYMax)
       
        uncut_inds = find (Y <= options.CutYMax);
        
        cut_inds = find (Y > options.CutYMax);
        
        for face_ind = 1:size(faces, 2)
            for vert_ind = 1:4
                if any (faces(vert_ind,face_ind) == cut_inds)
                    remove_face = [remove_face, face_ind];
                end
            end
        end
        
        faces(:,remove_face) = [];
        
        X = X(uncut_inds);
        Y = Y(uncut_inds);
        Z = Z(uncut_inds);
        
    end
    
    if ~isempty (options.CutYMin)
       
        uncut_inds = find (Y >= options.CutYMin);
        
        cut_inds = find (Y < options.CutYMin);
        
        for face_ind = 1:size(faces, 2)
            for vert_ind = 1:4
                if any (faces(vert_ind,face_ind) == cut_inds)
                    remove_face = [remove_face, face_ind];
                end
            end
        end
        
        faces(:,remove_face) = [];
        
        X = X(uncut_inds);
        Y = Y(uncut_inds);
        Z = Z(uncut_inds);
        
    end
    

    edge_inds = [];
    
    this_edge_inds = find (Z <= min(Z));

    tmpY2 = Y(this_edge_inds);

    [~, I] = sort (tmpY2, 'ascend');
    
    edge_inds = [ edge_inds; this_edge_inds(I)];
    
    this_edge_inds = find (Y >= max(Y));
    
    tmpZ2 = Z(this_edge_inds);
    
    [~, I] = sort (tmpZ2, 'ascend');
    
    edge_inds = [ edge_inds; this_edge_inds(I(2:end))];
    
    this_edge_inds = find (Z >= max(Z));
    
    tmpY2 = Y(this_edge_inds);
    
    [~, I] = sort (tmpY2, 'descend');
    
    edge_inds = [ edge_inds; this_edge_inds(I(2:end))];
    
    this_edge_inds = find (Y <= min(Y));
    
    tmpZ2 = Z(this_edge_inds);
    
    [~, I] = sort (tmpZ2, 'ascend');
    
    edge_inds = [ edge_inds; this_edge_inds(I(2:end-1))];


    % Project on sphere S2
    S = R*sqrt(1./(X.^2+Y.^2+Z.^2));
    X = X.*S;
    Y = Y.*S;
    Z = Z.*S;

    vertices = [ X(:), Y(:), Z(:) ].';

end