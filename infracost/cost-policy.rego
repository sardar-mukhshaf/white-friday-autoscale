package infracost

deny[out] {
  out := sprintf(
    "Cost increase of $%.2f/month exceeds the $500 threshold. Add 'cost-approved' label to proceed.",
    [input.totalMonthlyCost]
  )
  input.totalMonthlyCost > 500
}

warn[out] {
  out := sprintf(
    "Cost increase of $%.2f/month is significant. Please review.",
    [input.totalMonthlyCost]
  )
  input.totalMonthlyCost > 250
  input.totalMonthlyCost <= 500
}
