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

        public void UpdateRange( string newRange ){
            UpdateRange( newRange, this.Online );
        }

        public void UpdateRange( string newRange, bool online )
        {
            // update _isLocal
            _isLocal = !online;

            // update _range
            System.Management.Automation.PSObject semVer = ImportPackage.Globals.Instance.Bootstrapper.Properties["SemVer"].Value as System.Management.Automation.PSObject;
            _range = semVer.Methods["ReduceRanges"].Invoke( newRange, _range, false, _name, online ) as string;
            
            // update _selectedVersion and _isPrerelease
            // may need to be updated to better support prerelease versions
            System.Management.Automation.PSObject parsedRange = semVer.Methods["ParseRange"].Invoke( _range, false, _name, online ) as System.Management.Automation.PSObject;
            // this may need to be changed in future releases to support NuGet's versioning standards
            string newVersion = parsedRange.Properties["MaxVersion"].Value as string;
            UpdateSelectedVersion( newVersion, online );
        }

        public void UpdateSelectedVersion( string newVersion )
        {
            UpdateSelectedVersion( newVersion, this.Online );
        }

        public void UpdateSelectedVersion( string newVersion, bool online )
        {
            System.Management.Automation.PSObject bootstrapper = ImportPackage.Globals.Instance.Bootstrapper;
            System.Management.Automation.PSObject semVer = bootstrapper.Properties["SemVer"].Value as System.Management.Automation.PSObject;
            System.Management.Automation.PSObject parsedVer = semVer.Methods["Parse"].Invoke( newVersion ) as System.Management.Automation.PSObject;
            if( parsedVer == null ){
                throw new System.ArgumentException( "Invalid version string.", nameof(newVersion) );
            }
            //not equal to _selectedVersion
            if( parsedVer.Properties["Original"].Value as string != _selectedVersion ){
                _selectedVersion = parsedVer.Properties["Original"].Value as string;
                _isPrerelease = parsedVer.Properties["IsPrerelease"].Value as bool? ?? false;

                System.Collections.Generic.Dictionary<string,System.Object> platformData;
                platformData = bootstrapper.Methods["GetPlatformData"].Invoke( _name, _selectedVersion, online ) as System.Collections.Generic.Dictionary<string,System.Object>;
                _frameworkFiles = platformData["FrameworkFiles"] as System.Collections.Generic.Dictionary<string,System.Collections.Generic.List<string>>;
                _runtimeFiles = platformData["RuntimeFiles"] as System.Collections.Generic.Dictionary<string,System.Collections.Generic.Dictionary<string,System.Collections.Generic.List<string>>>;
            }
        }
    }
}