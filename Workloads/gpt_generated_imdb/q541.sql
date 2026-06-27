WITH rating AS (
    SELECT mi.movie_id,
           MAX(CAST(mi.info AS double)) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
),
actor_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT t.title,
       t.production_year,
       kt.kind,
       COALESCE(r.rating, 0) AS rating,
       COALESCE(ac.actor_count, 0) AS actor_count,
       COALESCE(kc.keyword_count, 0) AS keyword_count,
       COALESCE(cc.company_count, 0) AS company_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN rating r ON t.id = r.movie_id
LEFT JOIN actor_counts ac ON t.id = ac.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN company_counts cc ON t.id = cc.movie_id
WHERE t.production_year >= 2000
  AND kt.kind = 'movie'
ORDER BY rating DESC, actor_count DESC
LIMIT 100
