namespace ImportPackage
{
    public class Globals : System.Collections.Generic.IEnumerable<System.Collections.Generic.KeyValuePair<string, object>>
    {
        private static readonly Lazy<Globals> lazy =
            new Lazy<Globals>(() => new Globals());

        public static Globals Instance { get { return lazy.Value; } }

        private Globals()
        {
            _globals["Dependencies"] = new System.Collections.Generic.List<DependencyData>();
            // Private constructor to prevent instantiation from outside.
        }

        private bool _isBootstrapperSet = false;
        private System.Collections.Generic.Dictionary<string, object> _globals = new System.Collections.Generic.Dictionary<string, object>();

        public object this[string key]
        {
            get 
            { 
                return _globals.ContainsKey(key) ? _globals[key] : null;
            }
            set 
            { 
                Add( key, value );
            }
        }

        public void Add(string key, object value)
        {
            if( string.Equals( key, "Dependencies", StringComparison.CurrentCultureIgnoreCase ) ){
                throw new InvalidOperationException("Dependencies is a readonly property.");
            }

            if( string.Equals( key, "Bootstrapper", StringComparison.CurrentCultureIgnoreCase ) ){
                if( _isBootstrapperSet ){
                    throw new InvalidOperationException("Bootstrapper can only be set once.");
                }
                if (!(value is System.Management.Automation.PSObject))
                {
                    throw new ArgumentException("Value must be a PSObject.", nameof(value));
                }
                _isBootstrapperSet = true;
                _globals.Add("Bootstrapper", value);
                return;
            }

            if (!_globals.ContainsKey(key))
            {
                _globals.Add(key, value);
            }
        }

        public System.Management.Automation.PSObject Bootstrapper
        {
            get => _globals.ContainsKey("Bootstrapper") ? _globals["Bootstrapper"] as System.Management.Automation.PSObject : null;
            set
            {
                Add("Bootstrapper", value);
            }
        }

        public void Remove(string key)
        {
            if( string.Equals( key, "Bootstrapper", StringComparison.CurrentCultureIgnoreCase ) ){
                throw new InvalidOperationException("Bootstrapper can not be removed.");
            }
            _globals.Remove(key);
        }

        // Implementing IEnumerable
        public System.Collections.Generic.IEnumerator<System.Collections.Generic.KeyValuePair<string, object>> GetEnumerator()
        {
            return _globals.GetEnumerator();
        }

        System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator()
        {
            return GetEnumerator();
        }

        // Add any methods or properties here that you want to be part of the singleton.
    }
}