namespace ImportPackage
{
    public partial class DependencyData
    {
        private System.Collections.Generic.List<DependencyData> _dependencies = new System.Collections.Generic.List<DependencyData>();
        public System.Collections.Generic.List<DependencyData> Dependencies
        {
            get { return _dependencies; }
        }
    }
}