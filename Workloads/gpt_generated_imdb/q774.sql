/*
   Top 10 company types (e.g., production, distribution, etc.) ranked by the average
   number of distinct cast members per feature‑film.
   The query:
   1️⃣ Counts distinct cast members for each movie that is a "movie" (kind_type.kind = 'movie').
   2️⃣ Associates each movie with the company types that were involved.
   3️⃣ Aggregates per company type to compute:
        • Number of distinct movies the type participated in
        • Average, max and min distinct‑cast size for those movies
*/
WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast
    FROM cast_info ci
    JOIN title t
        ON ci.movie_id = t.id                     -- allowed join rule
    JOIN kind_type kt
        ON t.kind_id = kt.id                      -- allowed join rule
    WHERE kt.kind = 'movie'                       -- focus on feature films
      AND t.production_year IS NOT NULL
    GROUP BY t.id
),
movie_company_type AS (
    SELECT DISTINCT
        mc.movie_id,
        ct.kind AS company_type_kind
    FROM movie_companies mc
    JOIN company_type ct
        ON mc.company_type_id = ct.id             -- allowed join rule
)
SELECT
    mct.company_type_kind,
    COUNT(DISTINCT mct.movie_id) AS num_movies,
    AVG(mcc.distinct_cast)        AS avg_distinct_cast,
    MAX(mcc.distinct_cast)        AS max_distinct_cast,
    MIN(mcc.distinct_cast)        AS min_distinct_cast
FROM movie_company_type mct
JOIN movie_cast_counts mcc
    ON mct.movie_id = mcc.movie_id               -- joins derived tables on movie_id
GROUP BY mct.company_type_kind
ORDER BY avg_distinct_cast DESC
LIMIT 10
