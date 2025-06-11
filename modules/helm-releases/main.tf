resource "helm_release" "argo_cd" {
  name             = "argocd"
  repository       = var.argo_cd_repository
  chart            = "${path.module}/../../chart/argo-cd"
  version          = var.argo_cd_version
  namespace        = var.argo_cd_namespace
  create_namespace = true
  timeout          = 600

  values = [
    file("${path.module}/../../chart/argo-cd/values.custom.yaml")
  ]
}

resource "helm_release" "argocd_apps" {
  name             = "argocd-apps"
  chart            = "${path.module}/../../chart/argocd-apps"
  namespace        = var.argo_cd_namespace
  create_namespace = true
  depends_on       = [helm_release.argo_cd]
  timeout          = 600

  values = [
    var.environment == "prod" ? file("${path.module}/../../chart/argocd-apps/values.prod.yaml") : file("${path.module}/../../chart/argocd-apps/values.dev.yaml")
  ]
}