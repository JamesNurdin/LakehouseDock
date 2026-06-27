WITH budget_per_movie AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
),
cast_per_movie AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
companies_per_movie AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COALESCE(cpm.cast_count, 0) AS cast_count,
        COALESCE(cpmc.company_count, 0) AS company_count,
        bpm.budget
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_per_movie cpm ON cpm.movie_id = t.id
    LEFT JOIN companies_per_movie cpmc ON cpmc.movie_id = t.id
    LEFT JOIN budget_per_movie bpm ON bpm.movie_id = t.id
    WHERE t.production_year IS NOT NULL
)
SELECT
    md.production_year,
    md.kind,
    COUNT(DISTINCT md.movie_id) AS total_movies,
    AVG(md.cast_count) AS avg_cast_per_movie,
    AVG(md.company_count) AS avg_companies_per_movie,
    AVG(md.budget) AS avg_budget,
    SUM(md.budget) AS total_budget
FROM movie_details md
GROUP BY md.production_year, md.kind
ORDER BY total_movies DESC
LIMIT 20
