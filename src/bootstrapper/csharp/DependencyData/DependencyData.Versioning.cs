namespace ImportPackage
{
    public partial class DependencyData
    {
        private string _range;
        private string _selectedVersion;
        private bool _isPrerelease = false;
        private bool _isLocal = false;
        public string Range
        {
            get { return _range; }
            set { this.UpdateRange( value ); }
        }
        public string SelectedVersion
        {
            get { return _selectedVersion; }
            set { _selectedVersion = value; }
        }
        public bool IsPrerelease
        {
            get { return _isPrerelease; }
        }
        public bool Local { get { return _isLocal; } }
        public bool Online { get { return !_isLocal; } }

        public void UpdateRange( string newRange, bool online = this.Online )
        {
            // update _isLocal
            _isLocal = !online;

            // update _range
            System.Management.Automation.PSObject semVer = ImportPackage.Globals.Instance.Bootstrapper.Properties["SemVer"].Value as System.Management.Automation.PSObject;
            _range = semVer.Methods["ReduceRanges"].Invoke( newRange, _range, false, _name, online ) as string;
            
            // update _selectedVersion and _isPrerelease
            // may need to be updated to better support prerelease versions
            parsedRange = semVer.Methods["ParseRange"].Invoke( _range, false, _name, online  ) as System.Management.Automation.PSObject;
            // this may need to be changed in future releases to support NuGet's versioning standards
            newVersion = parsedRange.Properties["MaxVersion"].Value as string;
            UpdateSelectedVersion( newVersion );
        }

        public void UpdateSelectedVersion( string newVersion )
        {
            System.Management.Automation.PSObject semVer = ImportPackage.Globals.Instance.Bootstrapper.Properties["SemVer"].Value as System.Management.Automation.PSObject;
            parsedVer = semVer.Methods["Parse"].Invoke( newVersion ) as System.Management.Automation.PSObject;
            _selectedVersion = parsedVer.Properties["Original"].Value as string;
            _isPrerelease = parsedVer.Properties["IsPrerelease"].Value as bool? ?? false;
        }
    }
}