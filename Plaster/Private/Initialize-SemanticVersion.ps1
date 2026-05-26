if (-not ([System.Management.Automation.PSTypeName]'System.Management.Automation.SemanticVersion').Type) {
    Add-Type -TypeDefinition @'
namespace System.Management.Automation {
    public class SemanticVersion {
        public int Major { get; private set; }
        public int Minor { get; private set; }
        public int Patch { get; private set; }
        public SemanticVersion(string version) {
            var parts = version.Split('.');
            Major = int.Parse(parts[0]);
            Minor = parts.Length > 1 ? int.Parse(parts[1]) : 0;
            Patch = parts.Length > 2 ? int.Parse(parts[2]) : 0;
        }
        public override string ToString() {
            return Major + "." + Minor + "." + Patch;
        }
    }
}
'@
}
