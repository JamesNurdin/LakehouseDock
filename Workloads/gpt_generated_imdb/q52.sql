WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_size
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    GROUP BY t.id
),
company_movie_stats AS (
    SELECT
        mc.company_id,
        MIN(mc.company_type_id) AS company_type_id,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        AVG(mcc.cast_size) AS avg_cast_size
    FROM movie_companies mc
    JOIN movie_cast_counts mcc ON mc.movie_id = mcc.movie_id
    GROUP BY mc.company_id
)
SELECT
    cn.name AS company_name,
    ct.kind AS company_type,
    cms.movie_count,
    CAST(cms.avg_cast_size AS DOUBLE) AS avg_cast_size
FROM company_movie_stats cms
JOIN company_name cn ON cms.company_id = cn.id
JOIN company_type ct ON cms.company_type_id = ct.id
WHERE cms.movie_count >= 5
  AND ct.kind = 'production'
ORDER BY cms.avg_cast_size DESC
LIMIT 10
