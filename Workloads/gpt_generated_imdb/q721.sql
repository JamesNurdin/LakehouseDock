WITH cast_agg AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count,
           array_join(array_agg(DISTINCT n.name), ', ') AS cast_names
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id
),
company_agg AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_agg AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT t.title,
       t.production_year,
       kt.kind,
       COALESCE(ca.cast_count, 0) AS cast_count,
       COALESCE(ca.cast_names, '') AS cast_names,
       COALESCE(compa.company_count, 0) AS company_count,
       COALESCE(kw.keyword_count, 0) AS keyword_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_agg ca ON t.id = ca.movie_id
LEFT JOIN company_agg compa ON t.id = compa.movie_id
LEFT JOIN keyword_agg kw ON t.id = kw.movie_id
WHERE t.production_year > 2000
  AND kt.kind = 'movie'
ORDER BY cast_count DESC
LIMIT 10
