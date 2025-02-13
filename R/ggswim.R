#' @title Plot individual level response trajectories
#'
#' @description
#' Visualize individual record response trajectories over time using a swimmer plot.
#'
#' @details
#' A swimmer plot is a data visualization used to display individual
#' subject data over time. It shows events or outcomes as points along a
#' horizontal line for each subject, allowing easy comparison and pattern
#' identification.
#'
#' @param data a dataframe prepared for use with `ggswim()`
#' @param mapping Set of aesthetic mappings created by `aes()`. If specified and
#' `inherit.aes = TRUE` (the default), it is combined with the default mapping
#' at the top level of the plot. You must supply mapping if there is no plot mapping.
#' More information about accepted mapping arguments can be found in **Aesthetics**.
#' @param ... Other arguments passed to `ggswim()`, often aesthetic fixed values,
#' i.e. `color = "red"` or `size = 3`.
#'
#' @section Aesthetics:
#' `ggswim()` understands the following aesthetics (required aesthetics are in bold):
#'
#' - **`x`**
#' - **`y`**
#' - `alpha`
#' - `fill`
#' - `group`
#' - `linetype`
#' - `linewidth`
#'
#' **Note**: `ggswim()` **does not** support mapping using `color`/`colour`.
#'
#' @export

ggswim <- function(
    data,
    mapping = aes(),
    ...
) {
  # Enforce checks ----
  check_supported_mapping_aes(mapping = mapping,
                              unsupported_aes = c("color", "colour"),
                              parent_func = "add_marker()")

  # TODO: Finalize, determine if this is acceptable to enforce
  data[[mapping$y |> get_expr()]] <- data[[mapping$y |> get_expr()]] |> as.factor()

  out <- data |>
    ggplot() +
    geom_col(
      mapping,
      ...
    )

  # Define new class 'ggswim_obj'
  class(out) <- c("ggswim_obj", class(out))
  current_layer <- length(out$layers) # The max length can be considered the current working layer

  # Add a reference class to the layer attributes
  attributes(out$layers[[current_layer]])$swim_class <- "ggswim"

  # Return object
  out
}
