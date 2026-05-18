pkg_root <- normalizePath(file.path("..", ".."), winslash = "/", mustWork = TRUE)
r_files <- list.files(file.path(pkg_root, "R"), pattern = "\\.[Rr]$", full.names = TRUE)

for (path in sort(r_files)) {
    source(path, local = FALSE)
}
