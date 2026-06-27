WITH movies AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
),
cast_counts AS (
    SELECT ci.movie_id AS movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count,
           COUNT(DISTINCT ci.person_role_id) AS character_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id AS movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count,
           COUNT(DISTINCT ct.kind) AS company_type_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id AS movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
budget_info AS (
    SELECT mi.movie_id AS movie_id,
           MAX(CAST(mi.info AS double)) AS budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
    GROUP BY mi.movie_id
)
SELECT m.title,
       m.production_year,
       m.kind,
       COALESCE(cc.cast_count, 0) AS cast_count,
       COALESCE(cc.character_count, 0) AS character_count,
       COALESCE(compc.company_count, 0) AS company_count,
       COALESCE(compc.company_type_count, 0) AS company_type_count,
       COALESCE(kc.keyword_count, 0) AS keyword_count,
       b.budget
FROM movies m
LEFT JOIN cast_counts cc       ON m.movie_id = cc.movie_id
LEFT JOIN company_counts compc ON m.movie_id = compc.movie_id
LEFT JOIN keyword_counts kc    ON m.movie_id = kc.movie_id
LEFT JOIN budget_info b        ON m.movie_id = b.movie_id
ORDER BY cc.cast_count DESC
LIMIT 10
