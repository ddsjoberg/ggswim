#' Print ggswim
#'
#' @param x a ggswim object
#' @param ... not used
#'
#' @return a ggplot
#' @export
#'
#' @examples
#' # TODO: add example
print.ggswim_obj <- function(x, ...) {
  build_ggswim(x) |> print()
}
