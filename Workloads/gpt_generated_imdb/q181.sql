WITH budget_info AS (
    SELECT mi.movie_id,
           MAX(CAST(mi.info AS double)) AS budget
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'budget'
    GROUP BY mi.movie_id
),
base_movies AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           b.budget
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN budget_info b ON b.movie_id = t.id
    WHERE kt.kind = 'movie'
),
cast_counts AS (
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
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT bm.title,
       bm.production_year,
       bm.budget,
       COALESCE(cc.cast_count, 0) AS cast_count,
       COALESCE(compc.company_count, 0) AS company_count,
       COALESCE(kc.keyword_count, 0) AS keyword_count,
       ROW_NUMBER() OVER (ORDER BY bm.budget DESC NULLS LAST) AS budget_rank
FROM base_movies bm
LEFT JOIN cast_counts cc ON cc.movie_id = bm.movie_id
LEFT JOIN company_counts compc ON compc.movie_id = bm.movie_id
LEFT JOIN keyword_counts kc ON kc.movie_id = bm.movie_id
ORDER BY bm.budget DESC NULLS LAST
LIMIT 10
