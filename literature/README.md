# Literature Index

This index maps the stored PDF filenames in `literature/` to their bibliographic
identities, thesis relevance, and suggested citation locations. It is designed
so that a supervisor can understand the entire literature collection from this
single file without opening any PDF.

## Core Literature (read first)

These papers are central to the thesis argument and are already cited (or should
be) in the manuscript.

| Priority | Stored file                        | Author(s)                       | Year | Title                                                                                            | Topic                               | Thesis relevance                                                                                                                                                      | Suggested citation location                         |
| -------- | ---------------------------------- | ------------------------------- | ---: | ------------------------------------------------------------------------------------------------ | ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| **1**    | `mixed-precision/2602.04348v1.pdf` | Erin Claire Carson              | 2026 | _Balancing Inexactness in Mixed Precision Matrix Computations_                                   | Mixed-precision balancing principle | **Central** — the balancing-inexactness principle \(\eta*\mathrm{fp} \lesssim \eta*\mathrm{alg}\) is the organising principle for the thesis mixed-precision analysis | MixedPrecision §6, RandomizedCovarianceTransport §4 |
| **2**    | `s40641-016-0050-x-1.pdf`          | Douglas Maraun                  | 2016 | _Bias Correcting Climate Change Simulations — a Critical Review_                                 | Climate bias-correction review      | **Central** — the main cautionary reference for treating bias correction as non-trivial                                                                               | ClimateApplication §1, Introduction                 |
| **3**    | `clim-jcli-d-14-00059.1-1.pdf`     | Mathieu Vrac, Petra Friederichs | 2015 | _Multivariate–Intervariable, Spatial, and Temporal–Bias Correction_                              | Multivariate bias correction        | **Core** — ECBC/R2D2-style intervariable correction                                                                                                                   | ClimateApplication §2                               |
| **4**    | `hess-22-3175-2018.pdf`            | Mathieu Vrac                    | 2018 | _Multivariate bias adjustment of high-dimensional climate simulations: the R2D2 bias correction_ | R2D2 method                         | **Core** — rank-resampling for distributions and dependences                                                                                                          | ClimateApplication §2                               |

## Background Literature

These papers provide essential theoretical or methodological context but are not
the thesis's main objects of study.

| Priority | Stored file                                       | Author(s)                       | Year | Title                                                                                | Topic                    | Thesis relevance                                                                   | Suggested citation location |
| -------- | ------------------------------------------------- | ------------------------------- | ---: | ------------------------------------------------------------------------------------ | ------------------------ | ---------------------------------------------------------------------------------- | --------------------------- |
| **5**    | `13_Habilitation_Dissertation_Abbreviated(1).pdf` | Erin Claire Carson              | 2023 | _Mixed Precision Matrix Computations: Analysis and Algorithms_                       | Habilitation thesis      | **High** — comprehensive mixed-precision background; not yet in `bibliography.bib` | MixedPrecision §1–3         |
| **6**    | `140119625.pdf`                                   | Eda Oktay                       | 2024 | _Mixed-Precision Computations in Numerical Linear Algebra_                           | Doctoral manuscript      | **High** — mixed-precision NLA background; duplicate under `mixed-precision/`      | MixedPrecision §1–3         |
| **7**    | `rGMRES.pdf`                                      | Yuji Nakatsukasa, Joel A. Tropp | 2024 | _Fast and Accurate Randomized Algorithms for Linear Systems and Eigenvalue Problems_ | RandNLA solvers          | **Medium** — adjacent to sketch-and-precondition; not yet in bibliography          | RandomizedLeastSquares §8   |
| **8**    | `rsvd.pdf`                                        | N. Benjamin Erichson et al.     | 2019 | _Randomized Matrix Decompositions Using R_                                           | R-package implementation | **Medium** — implementation reference for the R-package side                       | package documentation       |

## Application-Side Literature

These papers illustrate the climate post-processing context. They are important
for the application chapter but are not the thesis's theoretical centre.

| Priority | Stored file                                                | Author(s)           | Year | Title                                                                                                            | Topic                        | Thesis relevance                                                                                           | Suggested citation location |
| -------- | ---------------------------------------------------------- | ------------------- | ---: | ---------------------------------------------------------------------------------------------------------------- | ---------------------------- | ---------------------------------------------------------------------------------------------------------- | --------------------------- |
| **9**    | `Effects_of_univariate_and_multivariate_bias_correc-1.pdf` | Judith Meyer et al. | 2018 | _Effects of univariate and multivariate bias correction on hydrological impact projections in alpine catchments_ | Hydrological bias correction | **Medium** — application-side evaluation of univariate vs multivariate correction; not yet in bibliography | ClimateApplication §3       |

## Peripheral Literature

| Priority | Stored file                        | Author(s)                  | Year | Title                                                   | Topic                     | Thesis relevance                         | Suggested citation location |
| -------- | ---------------------------------- | -------------------------- | ---: | ------------------------------------------------------- | ------------------------- | ---------------------------------------- | --------------------------- |
| **10**   | `mixed-precision/120444523.pdf`    | Josef Martnek              | 2023 | _Mixed Precision in Uncertainty Quantification Methods_ | Mixed-precision UQ        | **Low** — outside the main RandNLA focus | —                           |
| **11**   | `mixed-precision/2406.02701v3.pdf` | Mary Lai O. Salvana et al. | 2024 | _MPCR: Multi-Precision Computations Package in R_       | R mixed-precision tooling | **Low** — peripheral tooling reference   | package documentation       |
| —        | `130370638.pdf`                    | Ján Kovačovský             | 2023 | _Non-additive intermolecular interactions_              | Bachelor thesis           | **None** — unrelated earlier thesis      | —                           |

## Key References Not Yet Stored Locally

The following papers are already cited in `bibliography.bib` but do not yet
have stored PDFs. Adding them would complete the local collection.

| BibTeX key                 | Author(s)                | Year | Title                                                  | Why needed                     |
| -------------------------- | ------------------------ | ---: | ------------------------------------------------------ | ------------------------------ |
| `halko2011finding`         | Halko, Martinsson, Tropp | 2011 | _Finding structure with randomness_                    | Core RandNLA theory            |
| `martinsson2020randnla`    | Martinsson, Tropp        | 2020 | _Randomized numerical linear algebra_                  | Core RandNLA survey            |
| `woodruff2014sketching`    | Woodruff                 | 2014 | _Sketching as a tool for numerical linear algebra_     | Core OSE theory                |
| `higham2022mixed`          | Higham, Mary             | 2022 | _Mixed precision numerical linear algebra_             | Core mixed-precision reference |
| `bjorck1996leastsquares`   | Björck                   | 1996 | _Numerical Methods for Least Squares Problems_         | Core LS perturbation theory    |
| `cannon2015qdm`            | Cannon, Sobie, Murdock   | 2015 | _Bias correction of simulated climate by QDM_          | QDM method                     |
| `cannon2016mbc`            | Cannon                   | 2016 | _Multivariate bias correction of climate model output_ | MBCp/MBCr methods              |
| `cannon2018mbcn`           | Cannon                   | 2018 | _Multivariate quantile mapping bias correction_        | MBCn method                    |
| `francois2020multivariate` | François et al.          | 2020 | _Multivariate bias corrections of climate simulations_ | MBCn/R2D2 comparison           |
| `cannon2020mbcpackage`     | Cannon                   | 2020 | _MBC: Multivariate Bias Correction_                    | R package MBC                  |

## Duplicates

- `140119625.pdf` and `mixed-precision/140119625.pdf` are the same Eda Oktay
  document. Keep one canonical copy when the library is next cleaned.

## Gaps

- Several stored PDFs are not yet represented in `thesis/preamble/bibliography.bib`.
- The most important missing bibliography entries are for the Carson
  habilitation thesis and the Oktay manuscript.
- Several core references (Halko et al. 2011, Martinsson & Tropp 2020, Woodruff
  2014, Higham & Mary 2022, Björck 1996) are cited in the manuscript but do not
  yet have stored PDFs.
