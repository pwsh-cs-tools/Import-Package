namespace ImportPackage
{
    public partial class PackageData
    {
        private string _name;
        private string _version;
        private string _source;

        public string Name
        {
            get { return _name; }
        }
        public string Version
        {
            get { return _version; }
        }
        public string Source
        {
            get { return _source; }
        }

        public PackageData(string name, string version, string source)
        {
            _name = name;
            _version = version;
            _source = source;
        }
    }
}