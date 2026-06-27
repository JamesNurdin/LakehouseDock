WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
budget_info AS (
    SELECT mi.movie_id,
           MAX(CASE WHEN it.info = 'budget' THEN mi.info END) AS budget
    FROM movie_info mi
    JOIN info_type it ON it.id = mi.info_type_id
    GROUP BY mi.movie_id
),
movie_base AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt ON kt.id = t.kind_id
    WHERE t.production_year >= 2000
)
SELECT mb.title,
       mb.production_year,
       mb.kind,
       COALESCE(cc.cast_count, 0) AS cast_count,
       COALESCE(kc.keyword_count, 0) AS keyword_count,
       COALESCE(compc.company_count, 0) AS company_count,
       bi.budget
FROM movie_base mb
LEFT JOIN cast_counts cc      ON cc.movie_id     = mb.movie_id
LEFT JOIN keyword_counts kc   ON kc.movie_id     = mb.movie_id
LEFT JOIN company_counts compc ON compc.movie_id = mb.movie_id
LEFT JOIN budget_info bi      ON bi.movie_id     = mb.movie_id
ORDER BY cast_count DESC
LIMIT 10
