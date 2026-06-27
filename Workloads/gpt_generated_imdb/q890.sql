WITH movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT
    m.production_year,
    m.kind,
    COUNT(DISTINCT m.movie_id) AS num_movies,
    COALESCE(SUM(cc.cast_count), 0) AS total_cast_members,
    COALESCE(SUM(compc.company_count), 0) AS total_companies
FROM movies m
LEFT JOIN cast_counts cc ON m.movie_id = cc.movie_id
LEFT JOIN company_counts compc ON m.movie_id = compc.movie_id
GROUP BY m.production_year, m.kind
ORDER BY m.production_year DESC, m.kind
