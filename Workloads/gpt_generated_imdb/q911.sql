WITH actor_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS num_actors
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS num_keywords
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS num_companies
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
rating_agg AS (
    SELECT mi.movie_id,
           AVG(CAST(mi.info AS DOUBLE)) AS avg_rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
)
SELECT t.title,
       kt.kind,
       t.production_year,
       COALESCE(ac.num_actors, 0)      AS num_actors,
       ra.avg_rating,
       COALESCE(kc.num_keywords, 0)    AS num_keywords,
       COALESCE(cc.num_companies, 0)   AS num_companies
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN actor_counts ac ON ac.movie_id = t.id
LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
LEFT JOIN company_counts cc ON cc.movie_id = t.id
LEFT JOIN rating_agg ra ON ra.movie_id = t.id
WHERE t.production_year >= 2000
ORDER BY num_actors DESC, avg_rating DESC
LIMIT 10
