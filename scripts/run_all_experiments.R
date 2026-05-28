MASTER_SEED <- 20260527L

scripts <- c(
    "01_ls_sketch_size_sweep.R",
    "02_ls_conditioning_sweep.R",
    "03_ls_precision_sweep.R",
    "04_transport_rank_sweep.R",
    "05_transport_lambda_sweep.R",
    "06_transport_precision_sweep.R",
    "07_transport_basis_mode.R",
    "08_climate_synthetic_case.R",
    "09_climate_real_smoke.R"
)

run_dir <- file.path("results", format(Sys.Date(), "%Y-%m-%d"))
dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)

index_rows <- data.frame(
    script = character(),
    status = character(),
    elapsed = numeric(),
    stringsAsFactors = FALSE
)

for (script in scripts) {
    path <- file.path("experiments", script)
    if (!file.exists(path)) {
        message(sprintf("SKIP: %s not found", script))
        index_rows <- rbind(index_rows, data.frame(
            script = script, status = "MISSING", elapsed = NA_real_,
            stringsAsFactors = FALSE
        ))
        next
    }

    message(sprintf("RUNNING: %s", script))
    t0 <- proc.time()[[3L]]

    status <- tryCatch({
        source(path, local = new.env())
        "OK"
    }, error = function(e) {
        message(sprintf("ERROR in %s: %s", script, conditionMessage(e)))
        "ERROR"
    })

    elapsed <- proc.time()[[3L]] - t0
    index_rows <- rbind(index_rows, data.frame(
        script = script, status = status, elapsed = elapsed,
        stringsAsFactors = FALSE
    ))
}

utils::write.csv(index_rows, file.path(run_dir, "index.csv"), row.names = FALSE)
message(sprintf("\nDone. Index written to %s", file.path(run_dir, "index.csv")))
