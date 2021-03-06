classdef stateSpaceFilter < mbdyn.pre.genel
    
    properties (GetAccess = public, SetAccess = protected)
        
        A;
        B;
        C;
        D;
        E;
        stateOrder;
        gain;
        balance;
        value;
        derivative;
        
    end
    
    methods
        
        function self = stateSpaceFilter (state_order, A, B, C, varargin)
            
            options.E = [];
            options.D = [];
            options.Gain = []; % If a gain is supplied, all the coefficients of B are multiplied by the gain.
            options.Balance = '';
            options.Value = [];
            options.Derivative = [];
            
            options = parse_pv_pairs (options, varargin);
            
            assert (isnumeric (A), 'Matrix A must be numeric');
            assert (isnumeric (B), 'Matrix B must be numeric');
            assert (isnumeric (C), 'Matrix C must be numeric');
            
            if ~isempty (options.E)
                assert (isnumeric (options.E), 'Matrix E must be numeric');
            end
        
            if ~isempty (options.D)
                assert (isnumeric (options.D), 'Matrix D must be numeric');
            end
            
            if ~isempty (options.Balance)
                self.checkAllowedStringInputs  ( options.Balance, {'yes', 'no'}, true, 'Balance');
            end
            
            if ~isempty (options.Gain)
                assert (isnumeric (options.Gain) ...
                         && isscalar (options.Gain) ...
                         && isreal (options.Gain), ...
                        'Gain must be a real scalar numeric value');
            end
            
            if ~isempty (options.Value)
                assert (isnumeric (options.Value) ...
                         && isvector (options.Value) ...
                         && isreal (options.Value), ...
                        'Value must be a vector of real numeric values');
            end
            
            if ~isempty (options.Derivative)
                if isempty (options.Value)
                    error ('If you specify ''Derivative'' options, you must also specify ''Value''');
                end
                assert (isnumeric (options.Derivative) ...
                         && isvector (options.Derivative) ...
                         && isreal (options.Derivative) ...
                         && samesize (options.Value, options.Derivative), ...
                        'Derivative must be a vector of real numeric values, the same size as ''Value''');
            end
            
            
            self.A = A;
            self.B = B;
            self.C = C;
            self.D = options.D;
            self.E = options.E;
            
            self.stateOrder = state_order;
            
            self.gain = options.Gain;
            self.balance = options.Balance;
            self.value = options.Value;
            self.derivative = options.Derivative;
            
        end
        
        function str = generateMBDynInputString (self)
            
%             str = self.addOutputLine ('' , '', 1, false, 'one-mass body');
            
%             % delete newline character and space from start
%             str(1:2) = [];
            
%             str = self.addOutputLine (str, sprintf('body : %d, %d', self.label, self.nodeAttached.label), 1, true, 'label, node label');

            str = [self.formatInteger(self.stateOrder), ', # state order'];
            
            if ~isempty (self.E)
                str = self.addOutputLine (str, self.commaSepList ('Matrix E'), 0, true);
                str = self.addOutputLine (str, self.writeMatrix (self.E, false), 0, true);
            end
            
            str = self.addOutputLine (str, self.commaSepList ('Matrix A'), 0, true);
            
            str = self.addOutputLine (str, self.writeMatrix (self.A, false), 0, true);
            
            str = self.addOutputLine (str, self.commaSepList ('Matrix B'), 0, true);
            
            str = self.addOutputLine (str, self.writeMatrix (self.B, false), 0, true);
            
            addcomma = ~isempty (self.D) || ~isempty (self.gain) || ~isempty (self.balance) || ~isempty (self.value);
            str = self.addOutputLine (str, self.commaSepList ('Matrix C'), 0, true);
            str = self.addOutputLine (str, self.writeMatrix (self.C, false), 0, addcomma);
            
            addcomma = ~isempty (self.gain) || ~isempty (self.balance) || ~isempty (self.value);
            
            if ~isempty (self.D)
                str = self.addOutputLine (str, self.commaSepList ('Matrix D'), 0, true);
                str = self.addOutputLine (str, self.writeMatrix (self.D, false), 0, addcomma);
            end
            
            addcomma = ~isempty (self.balance) || ~isempty (self.value);
            
            if ~isempty (self.gain)
                str = self.addOutputLine (str, self.commaSepList ('gain', self.gain), 0, addcomma);
            end
            
            addcomma = ~isempty (self.value);
            
            if ~isempty (self.balance)
                str = self.addOutputLine (str, self.commaSepList ('balance', self.balance), 0, addcomma);
            end

            if ~isempty (self.value)
                
                addcomma = ~isempty (self.derivative);
                str = self.addOutputLine (str, self.commaSepList ('value', self.value), 0, addcomma);
                
                if ~isempty (self.derivative)
                    str = self.addOutputLine (str, self.commaSepList ('derivative', self.derivative), 1, false);
                end
                
            end
            
%             str = self.addOutputLine (str, ';', 1, false, 'end state space');
            
        end
        
%         function hax = draw (self, varargin)
%             
%             options.AxesHandle = [];
%             options.ForceRedraw = false;
%             options.Mode = 'solid';
%             options.Light = false;
%             
%             options = parse_pv_pairs (options, varargin);
%             
%             hax = draw@mbdyn.pre.element ( self, ...
%                     'AxesHandle', options.AxesHandle, ...
%                     'ForceRedraw', options.ForceRedraw, ...
%                     'Mode', options.Mode, ...
%                     'Light', options.Light );
% 
%             self.setTransform ();
%             
%         end
        
    end
    
    methods (Access = protected)
        
        
        
    end
    
end