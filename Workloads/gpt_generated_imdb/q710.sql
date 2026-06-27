WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_agg AS (
    SELECT mk.movie_id,
           array_join(array_agg(DISTINCT k.keyword), ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    COALESCE(cc.cast_count, 0)      AS cast_count,
    COALESCE(compc.company_count, 0) AS company_count,
    COALESCE(ka.keywords, '')        AS keywords
FROM title t
LEFT JOIN cast_counts cc     ON cc.movie_id = t.id
LEFT JOIN company_counts compc ON compc.movie_id = t.id
LEFT JOIN keyword_agg ka      ON ka.movie_id = t.id
WHERE t.production_year >= 2010
ORDER BY t.production_year DESC,
         cast_count DESC
LIMIT 100
