#!/usr/bin/env Rscript

# Population Structure Visualization Script
# This script creates publication-quality visualizations for population structure analysis
# Usage: Rscript visualize_results.R <results_dir> [options]

# Load required libraries
required_packages <- c("ggplot2", "dplyr", "reshape2", "RColorBrewer", 
                      "gridExtra", "cowplot", "viridis", "argparse")

# Function to install missing packages
install_missing_packages <- function(packages) {
    missing <- packages[!packages %in% installed.packages()[,"Package"]]
    if(length(missing) > 0) {
        cat("Installing missing packages:", paste(missing, collapse=", "), "\n")
        install.packages(missing, repos="https://cran.r-project.org")
    }
}

# Install missing packages
install_missing_packages(required_packages)

# Load libraries
suppressMessages({
    library(ggplot2)
    library(dplyr)
    library(reshape2)
    library(RColorBrewer)
    library(gridExtra)
    library(cowplot)
    library(viridis)
})

# Default parameters
default_output_dir <- "output/visualization"
default_width <- 12
default_height <- 8
default_dpi <- 300

# Function to display usage
show_usage <- function() {
    cat("Usage: Rscript visualize_results.R <results_dir> [options]\n")
    cat("\n")
    cat("Required arguments:\n")
    cat("  results_dir     Directory containing aligned results from CLUMPAK\n")
    cat("\n")
    cat("Optional arguments:\n")
    cat("  --output-dir D  Output directory for plots (default: output/visualization)\n")
    cat("  --width N       Plot width in inches (default: 12)\n")
    cat("  --height N      Plot height in inches (default: 8)\n")
    cat("  --dpi N         Plot resolution (default: 300)\n")
    cat("  --format F      Output format: png, pdf, or both (default: both)\n")
    cat("  --theme T       Plot theme: minimal, classic, or bw (default: minimal)\n")
    cat("  --help         Show this help message\n")
    cat("\n")
    cat("Example:\n")
    cat("  Rscript visualize_results.R output/clumpak --width 14 --format pdf\n")
    quit(status=1)
}

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

if(length(args) == 0 || "--help" %in% args) {
    show_usage()
}

# Parse arguments manually (simplified approach)
results_dir <- args[1]
output_dir <- default_output_dir
plot_width <- default_width
plot_height <- default_height
plot_dpi <- default_dpi
output_format <- "both"
plot_theme <- "minimal"

# Simple argument parsing
for(i in 2:length(args)) {
    if(args[i] == "--output-dir" && i < length(args)) {
        output_dir <- args[i+1]
    } else if(args[i] == "--width" && i < length(args)) {
        plot_width <- as.numeric(args[i+1])
    } else if(args[i] == "--height" && i < length(args)) {
        plot_height <- as.numeric(args[i+1])
    } else if(args[i] == "--dpi" && i < length(args)) {
        plot_dpi <- as.numeric(args[i+1])
    } else if(args[i] == "--format" && i < length(args)) {
        output_format <- args[i+1]
    } else if(args[i] == "--theme" && i < length(args)) {
        plot_theme <- args[i+1]
    }
}

# Validate inputs
if(!dir.exists(results_dir)) {
    cat("Error: Results directory not found:", results_dir, "\n")
    quit(status=1)
}

# Create output directory
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

cat("=== Population Structure Visualization Started ===\n")
cat("Results directory:", results_dir, "\n")
cat("Output directory:", output_dir, "\n")
cat("Plot dimensions:", plot_width, "x", plot_height, "inches\n")
cat("Resolution:", plot_dpi, "dpi\n")
cat("Format:", output_format, "\n")
cat("Theme:", plot_theme, "\n\n")

# Set plot theme
if(plot_theme == "minimal") {
    theme_set(theme_minimal())
} else if(plot_theme == "classic") {
    theme_set(theme_classic())
} else if(plot_theme == "bw") {
    theme_set(theme_bw())
}

# Function to read Q matrix files
read_q_matrix <- function(file_path, method_name, k_value) {
    if(!file.exists(file_path)) {
        cat("Warning: File not found:", file_path, "\n")
        return(NULL)
    }
    
    q_data <- read.table(file_path, header = FALSE, stringsAsFactors = FALSE)
    
    # Add individual IDs and method information
    q_data$Individual <- paste0("Ind_", 1:nrow(q_data))
    q_data$Method <- method_name
    q_data$K <- k_value
    
    return(q_data)
}

# Function to create population structure bar plot
create_structure_barplot <- function(q_data, k_value, method_name) {
    # Reshape data for plotting
    q_melted <- reshape2::melt(q_data, 
                              id.vars = c("Individual", "Method", "K"),
                              variable.name = "Cluster", 
                              value.name = "Ancestry")
    
    # Create color palette
    if(k_value <= 8) {
        colors <- RColorBrewer::brewer.pal(max(3, k_value), "Set2")[1:k_value]
    } else {
        colors <- viridis(k_value)
    }
    
    # Create bar plot
    p <- ggplot(q_melted, aes(x = Individual, y = Ancestry, fill = Cluster)) +
        geom_bar(stat = "identity", width = 1, color = "white", size = 0.1) +
        scale_fill_manual(values = colors) +
        scale_y_continuous(expand = c(0, 0)) +
        labs(title = paste(method_name, "Population Structure (K =", k_value, ")"),
             x = "Individuals",
             y = "Ancestry Proportion",
             fill = "Cluster") +
        theme(axis.text.x = element_blank(),
              axis.ticks.x = element_blank(),
              panel.grid = element_blank(),
              legend.position = "bottom")
    
    return(p)
}

# Function to read CV error file (ADMIXTURE)
read_cv_errors <- function(cv_file) {
    if(!file.exists(cv_file)) {
        cat("Warning: CV error file not found:", cv_file, "\n")
        return(NULL)
    }
    
    cv_data <- read.table(cv_file, header = TRUE, stringsAsFactors = FALSE)
    cv_data$CV_Error <- as.numeric(cv_data$CV_Error)
    cv_data <- cv_data[!is.na(cv_data$CV_Error), ]
    
    return(cv_data)
}

# Function to create CV error plot
create_cv_plot <- function(cv_data) {
    if(is.null(cv_data) || nrow(cv_data) == 0) {
        return(NULL)
    }
    
    p <- ggplot(cv_data, aes(x = K, y = CV_Error)) +
        geom_line(color = "blue", size = 1) +
        geom_point(color = "blue", size = 3) +
        geom_point(data = cv_data[which.min(cv_data$CV_Error), ], 
                   color = "red", size = 4) +
        labs(title = "ADMIXTURE Cross-Validation Error",
             x = "Number of Clusters (K)",
             y = "Cross-Validation Error") +
        theme(panel.grid.minor = element_blank())
    
    return(p)
}

# Function to save plots
save_plot <- function(plot, filename, width = plot_width, height = plot_height) {
    if(is.null(plot)) {
        cat("Warning: Cannot save NULL plot for", filename, "\n")
        return()
    }
    
    if(output_format %in% c("png", "both")) {
        ggsave(paste0(filename, ".png"), plot, 
               width = width, height = height, dpi = plot_dpi)
    }
    
    if(output_format %in% c("pdf", "both")) {
        ggsave(paste0(filename, ".pdf"), plot, 
               width = width, height = height)
    }
    
    cat("Saved plot:", basename(filename), "\n")
}

# Main visualization workflow
cat("Step 1: Reading aligned results...\n")

# [TO BE FILLED] - Read aligned Q matrices from CLUMPAK output
# This section will be expanded to read actual CLUMPAK output files
admixture_files <- list.files(file.path(results_dir, "admixture"), 
                             pattern = "\\.Q$", full.names = TRUE)
structure_files <- list.files(file.path(results_dir, "structure"), 
                             pattern = "\\.Q$", full.names = TRUE)

cat("Found ADMIXTURE files:", length(admixture_files), "\n")
cat("Found STRUCTURE files:", length(structure_files), "\n")

# [TO BE FILLED] - Process actual data files
cat("\n# [TO BE FILLED] - File reading and processing will be expanded here\n")
cat("# This will include:\n")
cat("# 1. Reading aligned Q matrices from CLUMPAK\n")
cat("# 2. Reading population/sample metadata\n")
cat("# 3. Reading geographic coordinates (if available)\n")
cat("# 4. Processing CV errors and log-likelihoods\n\n")

# Create example data for demonstration
cat("Step 2: Creating example visualizations...\n")

# Generate example data (placeholder)
example_k_values <- 2:6
example_individuals <- 50

for(k in example_k_values) {
    # Create example Q matrix
    set.seed(k * 42)  # Reproducible example
    q_matrix <- matrix(runif(example_individuals * k), 
                      nrow = example_individuals, ncol = k)
    q_matrix <- t(apply(q_matrix, 1, function(x) x/sum(x)))  # Normalize
    
    # Convert to data frame
    q_df <- as.data.frame(q_matrix)
    colnames(q_df) <- paste0("V", 1:k)
    q_df$Individual <- paste0("Ind_", 1:example_individuals)
    q_df$Method <- "Example"
    q_df$K <- k
    
    # Create and save bar plot
    bar_plot <- create_structure_barplot(q_df, k, "Example ADMIXTURE")
    save_plot(bar_plot, file.path(output_dir, paste0("structure_barplot_K", k)))
}

# Create example CV error plot
cat("Step 3: Creating cross-validation plot...\n")
example_cv <- data.frame(
    K = 2:10,
    CV_Error = c(0.45, 0.42, 0.38, 0.35, 0.37, 0.41, 0.45, 0.49, 0.52)
)
cv_plot <- create_cv_plot(example_cv)
save_plot(cv_plot, file.path(output_dir, "cv_error_plot"))

# [TO BE FILLED] - Additional visualization functions
cat("\nStep 4: Creating additional visualizations...\n")
cat("# [TO BE FILLED] - Additional plots will be added:\n")
cat("# 1. Method comparison plots\n")
cat("# 2. Geographic maps (if coordinates available)\n")
cat("# 3. PCA plots\n")
cat("# 4. Similarity heatmaps\n")
cat("# 5. Summary statistics plots\n")

# Create summary report
cat("\nStep 5: Creating summary report...\n")
summary_file <- file.path(output_dir, "visualization_summary.txt")
cat("# Population Structure Visualization Summary\n", file = summary_file)
cat("# Generated on:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n", 
    file = summary_file, append = TRUE)
cat("Input directory:", results_dir, "\n", file = summary_file, append = TRUE)
cat("Output directory:", output_dir, "\n", file = summary_file, append = TRUE)
cat("Plots generated for K values:", paste(example_k_values, collapse = ", "), "\n", 
    file = summary_file, append = TRUE)

# List generated files
cat("\n=== Visualization Completed ===\n")
cat("Output directory:", output_dir, "\n")
cat("Generated files:\n")
output_files <- list.files(output_dir, full.names = FALSE)
for(file in output_files) {
    cat("  ", file, "\n")
}

cat("\nVisualization complete! Check the output directory for plots.\n")
cat("\nNext steps:\n")
cat("1. Review structure bar plots for different K values\n")
cat("2. Use CV error plot to select optimal K\n")
cat("3. Compare results between methods\n")
cat("4. Customize plots for publication if needed\n")

# [TO BE FILLED] - Add function for creating combined comparison plots
# [TO BE FILLED] - Add function for creating geographic visualizations
# [TO BE FILLED] - Add function for creating PCA plots
# [TO BE FILLED] - Add interactive plotting options