WITH cast_per_movie AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_size
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_per_movie AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
production_movies AS (
    SELECT DISTINCT
        mc.movie_id
    FROM movie_companies mc
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    WHERE ct.kind = 'production company'
)
SELECT
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(cpm.cast_size) AS avg_cast_size,
    SUM(kpm.keyword_count) AS total_keyword_count
FROM title t
JOIN production_movies pm
    ON t.id = pm.movie_id
LEFT JOIN cast_per_movie cpm
    ON t.id = cpm.movie_id
LEFT JOIN keyword_per_movie kpm
    ON t.id = kpm.movie_id
WHERE t.production_year IS NOT NULL
  AND t.kind_id = 1
GROUP BY t.production_year
ORDER BY t.production_year DESC
