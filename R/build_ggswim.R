#' @title Apply ggswim fixes and display updates
#'
#' @description
#' This function seeks to correct the output of manual overrides introduced by
#' `add_marker()` depending on the combination of layer types the user provides.
#'
#' It is to be run automatically in the background as a print method via
#' `print.ggswim_obj()`.
#'
#' @details
#' In its current state, `build_ggswim()` can only work with a pre-rendered
#' ggswim plot object, therefore it cannot be added to the `+` operator chain.
#'
#' `build_ggswim()` makes use of `ggplot2::guides()` to dynamically override
#' displays in the layers of the ggswim legend. It also applies a call to
#' `ggplot2::scale_color_manual()` in applicable cases where a user calls out
#' a static `color`/`colour` argument in addition to the required `color`
#' mapping aesthetic (handled by arg: `name`).
#'
#' @param ggswim_obj A ggswim object
#'
#' @returns A ggswim object
#' @export

build_ggswim <- function(ggswim_obj) {

  # Set up initial capture variables ----
  # Indices for layer positions in ggswim_obj
  label_layer_indices <- c()
  point_layer_indices <- c()
  # Layer data for ggswim_obj data layer capture
  label_layer_data <- data.frame()
  point_layer_data <- data.frame()

  # static_colours for static color manipulation and legend re-definition
  static_colours <- list()
  # override for guides legend override
  override <- list()

  # Determine indices of layers in ggplot object that contain labels, points, and static colors
  for (i in seq_along(ggswim_obj$layers)) {
    if (attributes(ggswim_obj$layers[[i]])$swim_class == "marker_label") {
      label_layer_indices <- c(label_layer_indices, i)
    }

    if (attributes(ggswim_obj$layers[[i]])$swim_class == "marker_point") {
      point_layer_indices <- c(point_layer_indices, i)
    }

    if (!is.null(ggswim_obj$layers[[i]]$static_colours)) {
      static_colours$indices <- c(static_colours$indices, i)
      static_colours$colors <- c(static_colours$colors, ggswim_obj$layers[[i]]$static_colours)
      static_colours$name <- c(static_colours$name, ggswim_obj$layers[[i]]$mapping$colour |> get_expr() |> as.character())
    }
  }

  # Convert static_colours to a dataframe (will always have equal col lengths)
  static_colours <- data.frame(static_colours)

  # If no `add_marker()` calls, then no need to build legend, exiting early ----
  # requires indices to be built first for determination
  if (rlang::is_empty(label_layer_indices) && rlang::is_empty(point_layer_indices)) {
    # remove ggswim class, so default ggplot2 print methods will take over
    return(
      ggswim_obj |>
        structure(class = class(ggswim_obj) |> setdiff("ggswim_obj"))
    )
  }

  # Create bound layer dataframes ----
  label_layer_data <- bind_layer_data(ggswim_obj,
                                      layer_indices = label_layer_indices,
                                      layer_data = label_layer_data)

  point_layer_data <- bind_layer_data(ggswim_obj,
                                      layer_indices = point_layer_indices,
                                      layer_data = point_layer_data,
                                      static_colours = static_colours)

  # TODO: Verify all acceptable column names
  accepted_colour_columns <- c(
    "colour", "label", "group", "fill", "size", "shape", "stroke", "colour_mapping"
  )

  # Define override aesthetic guides
  override$colour <- bind_rows(label_layer_data, point_layer_data) |>
    select(any_of(accepted_colour_columns))

  if ("colour_mapping" %in% names(override$colour)){
    # Arrange necessary to follow order of ggplot legend outputs
    # (i.e. alphabetical, numeric, etc.)
    override$colour <- override$colour |>
      select(-dplyr::matches("group")) |> # TODO: Implemented due to NA vals with no add_marker() data, confirm acceptable
      arrange(.data$colour_mapping) |>
      unique()
  }

  # Handle forcing of labels into color aesthetic of legend
  if ("label" %in% names(override$colour)) {
    override$colour$label[is.na(override$colour$label)] <- ""
  }

  override$shape <- "none" # TODO: Determine if default should always be removal

  # Return fixed ggswim object
  (ggswim_obj +
      scale_color_manual(values = setNames(override$colour$colour,
                                           override$colour$colour_mapping)) +
      guides(
        shape = override$shape,
        colour = guide_legend(
          override.aes = list(
            label = override$colour$label,
            fill = override$colour$fill,
            color = override$colour$colour,
            shape = override$colour$shape
          )
        )
      )) |>
    # remove ggswim class, so default ggplot2 print methods will take over
    structure(class = class(ggswim_obj) |> setdiff("ggswim_obj"))
}


#' @title Bind layer dataframes for legend
#'
#' @description
#' Internal helper function that returns layer data from `get_layer_data()`
#' as a bound dataframe to help with legend guide definitions.
#'
#' @returns A dataframe
#'
#' @param ggswim_obj description
#' @param layer_indices description
#' @param layer_data description
#' @param static_colours description
#'
#' @keywords internal

bind_layer_data <- function(ggswim_obj, layer_indices, layer_data, static_colours = NULL) {
  for (i in layer_indices) {
    # If first layer, overwrite empty variable
    if (is_empty(layer_data)) {
      layer_data <- get_layer_data(data = if (
        # Handle instances where add_marker() inherits data from ggswim()
        is_empty(ggswim_obj$layers[[i]]$data)
      ) {
        ggswim_obj$data
      } else {
        ggswim_obj$layers[[i]]$data
      },
      mapping = ggswim_obj$layers[[i]]$mapping,
      i = i,
      static_colours = static_colours)
    } else {
      added_layer_data <- get_layer_data(data = ggswim_obj$layers[[i]]$data,
                                         mapping = ggswim_obj$layers[[i]]$mapping,
                                         i = i,
                                         static_colours = static_colours)

      layer_data <- bind_rows(layer_data, added_layer_data)
    }
  }

  layer_data
}
