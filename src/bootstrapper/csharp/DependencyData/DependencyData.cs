namespace ImportPackage
{
    public partial class DependencyData
    {
        private string _name;
        public string Name
        {
            get { return _name; }
        }

        public DependencyData( string name, string range = "[0.0.0,)", bool online = true )
        {
            _name = name;
            UpdateRange( range, online );
        }
    }
}