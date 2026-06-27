WITH cast_agg AS (
    SELECT ci.movie_id AS movie_id,
           COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id
),
company_agg AS (
    SELECT mc.movie_id AS movie_id,
           COUNT(DISTINCT cn.id) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
keyword_agg AS (
    SELECT mk.movie_id AS movie_id,
           COUNT(DISTINCT k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT t.title,
       t.production_year,
       kt.kind,
       COALESCE(ca.actor_count, 0)      AS actor_count,
       COALESCE(cpa.company_count, 0)   AS company_count,
       COALESCE(ka.keyword_count, 0)    AS keyword_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_agg ca   ON t.id = ca.movie_id
LEFT JOIN company_agg cpa ON t.id = cpa.movie_id
LEFT JOIN keyword_agg ka ON t.id = ka.movie_id
WHERE t.production_year >= 2000
ORDER BY actor_count DESC
LIMIT 10
