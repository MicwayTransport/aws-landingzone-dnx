resource "aws_iam_instance_profile" "packer" {
  name = "packer-builder"
  role = resource.aws_iam_role.ci_deploy_access.name
}

resource "aws_iam_role_policy_attachment" "ssm_manage_instance" {
  role       = resource.aws_iam_role.ci_deploy_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
