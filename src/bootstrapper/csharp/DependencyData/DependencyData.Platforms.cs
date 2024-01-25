namespace ImportPackage
{
    public partial class DependencyData
    {
        // if this is empty, the package may be cross-framework (i.e /lib/*.dll instead of /lib/*/*.dll)
        private System.Collections.Generic.Dictionary<string,System.Collections.Generic.List<string>> _frameworkFiles;
        private System.Collections.Generic.Dictionary<string,System.Collections.Generic.Dictionary<string,System.Collections.Generic.List<string>>> _runtimeFiles;

        public System.Collections.Generic.Dictionary<string,System.Collections.Generic.List<string>> FrameworkFiles
        {
            get { return _frameworkFiles; }
        }
        public System.Collections.Generic.Dictionary<string,System.Collections.Generic.Dictionary<string,System.Collections.Generic.List<string>>> RuntimeFiles
        {
            get { return _runtimeFiles; }
        }

        // updated by UpdateSelectedVersion()
    }
}