function mbsys = make_multibody_system (waves, spar_hbody, float_hbody)

    gref = mbdyn.pre.globalref;

    ref_seabed = mbdyn.pre.reference ( [0;0;-waves.waterDepth], [], [], [], 'Parent', gref); 

    % Float
    ref_float = mbdyn.pre.reference ( float_hbody.cg, [], [], [], 'Parent', gref);

    float_node = mbdyn.pre.structuralNode6dof ('dynamic', 'AbsolutePosition', ref_float.pos);

    float_mb_body = mbdyn.pre.body ( float_hbody.mass,  ...
                                     [0;0;0], ...
                                     diag (float_hbody.momOfInertia), ...
                                     float_node, ...
                                     'STLFile', fullfile (simu.caseDir, float_hbody.geometryFile) );

    float_mb_body.setSize (20, 20, 5);

    % make it a yellow colour
    float_mb_body.setColour ([247, 244, 17]./255);

    % Spar
    ref_spar = mbdyn.pre.reference ( spar_hbody.cg, [], [], [], 'Parent', gref);

    spar_node = mbdyn.pre.structuralNode6dof ('dynamic', 'AbsolutePosition', ref_spar.pos);

    spar_mb_body = mbdyn.pre.body ( spar_hbody.mass, ...
                                    [0;0;0], ...
                                    diag (spar_hbody.momOfInertia), ...
                                    spar_node, ...
                                    'STLFile', fullfile (simu.caseDir, spar_hbody.geometryFile) );

    spar_mb_body.setSize (6, 6, 38);

    % make it a grey colour
    spar_mb_body.setColour ([181, 181, 181]./255);


    % create a node to clamp to the global frame which we can use to attach a
    % planar joint (actually made up of two joints) to the spar.
    %
    % Since  we are going to clamp the node, we can make it static (getting rid
    % of the degrees of freedom associated with it)
    clamped_node = mbdyn.pre.structuralNode6dof ('static', 'AbsolutePosition', ref_seabed.pos);
    % clamp it
    jclamp = mbdyn.pre.clamp (clamped_node, 'node', 'node');

    % add the joints
    j1 = mbdyn.pre.prismatic (float_node, spar_node);

    om = mbdyn.pre.orientmat ('2vectors', struct ('ia', 1, 'vecA', [1., 0., 0.], 'ib', 3, 'vecB', [0., 0., 1.]));
    j2 = mbdyn.pre.inline (float_node, spar_node, 'RelativeLinePosition', [0;0;0], ...
                                                  'RelativeOrientation', om, ...
                                                  'OrientationReference', 'global');

    j3 = mbdyn.pre.inPlane (  clamped_node, spar_node, [0;1;0], ...
                            'RelativeOffset', 'null', ...
                            'RelativeOffsetReference', 'other node');

    j4 = mbdyn.pre.revoluteRotation ( spar_node, clamped_node, ...
                                     'RelativeOffset1', 'null', ...
                                     'RelativeOffset1Reference', 'node', ...
                                     'RelativeOffset2', 'null', ...
                                     'RelativeOffset2Reference', 'other node', ...
                                     'RelativeOrientation1', mbdyn.pre.orientmat ('2vectors', struct ('ia', 1, 'vecA', [1,0,0], 'ib', 2, 'vecB', [0,0,1])), ...
                                     'RelativeOrientation2', mbdyn.pre.orientmat ('2vectors', struct ('ia', 1, 'vecA', [1,0,0], 'ib', 2, 'vecB', [0,0,1])));


    if ispc
        % add the socket forces
        communicator = mbdyn.pre.socketCommunicator ('Port', 5500, ...
                                                     'Coupling', 'tight', ...
                                                     'Create', 'yes', ...
                                                     'SleepTime', 0, ...
                                                     'SendAfterPredict', 'no');
    else
        % add the socket forces
        communicator = mbdyn.pre.socketCommunicator ('Path', '/tmp/mbdyn.sock', ...
                                                     'Coupling', 'tight', ...
                                                     'Create', 'yes', ...
                                                     'SleepTime', 0, ...
                                                     'SendAfterPredict', 'no');
    end

    socket_force = mbdyn.pre.externalStructuralForce ({float_node, spar_node}, [], communicator, ...
                                                      'Labels', 'no', ...
                                                      'Sorted', 'yes', ...
                                                      'Orientation', 'orientation matrix' ... , ...
                                                      ... 'Echo', fullfile (simu.caseDir, 'output', 'socket_echo.txt') ...
                                                      );

    prob = mbdyn.pre.initialValueProblem (simu.startTime, simu.endTime, simu.dt, ...
                                    'Tol', 1e-6, 'MaxIterations', 20);

    % assemble the system
    mbsys = mbdyn.pre.system ( prob, ...
                               'Nodes', {float_node, spar_node, clamped_node}, ...
                               'Elements', {float_mb_body, spar_mb_body, jclamp, j1, j2, j3, j4 socket_force} );

end