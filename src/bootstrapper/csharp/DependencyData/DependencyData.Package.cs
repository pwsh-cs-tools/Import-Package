namespace ImportPackage
{
    public partial class DependencyData
    {
        private ImportPackage.PackageData _generatedPackage;
        public ImportPackage.PackageData Package
        {
            get { return _generatedPackage; }
        }

        public ImportPackage.PackageData GeneratePackage()
        {
            _generatedPackage = new ImportPackage.PackageData( _name, null, null );
            return null;
        }
    }
}