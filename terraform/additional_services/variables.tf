variable "emr_launcher_zip" {
  type = map(string)
  default = {
    base_path = "../emr-launcher-release"
    version   = "1.0.36"
  }
}
