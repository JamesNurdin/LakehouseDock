WITH company_movies AS (
    SELECT
        cn.id AS company_id,
        cn.name AS company_name,
        t.id AS movie_id,
        t.title,
        t.production_year
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN title t ON mc.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE ct.kind = 'production company'
      AND kt.kind = 'movie'
),
movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_runtime AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS integer) AS runtime_minutes
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
)
SELECT
    cm.company_name,
    COUNT(DISTINCT cm.movie_id) AS total_movies,
    COUNT(DISTINCT ci.person_id) AS total_distinct_cast,
    AVG(mcc.distinct_cast_count) AS avg_cast_per_movie,
    AVG(mr.runtime_minutes) AS avg_runtime_minutes
FROM company_movies cm
LEFT JOIN cast_info ci ON ci.movie_id = cm.movie_id
LEFT JOIN movie_cast_counts mcc ON mcc.movie_id = cm.movie_id
LEFT JOIN movie_runtime mr ON mr.movie_id = cm.movie_id
GROUP BY cm.company_name
ORDER BY total_movies DESC
LIMIT 10
