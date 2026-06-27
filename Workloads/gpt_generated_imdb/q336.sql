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
info_counts AS (
    SELECT mi.movie_id,
           COUNT(*) AS info_count
    FROM movie_info mi
    GROUP BY mi.movie_id
),
movie_details AS (
    SELECT t.id        AS movie_id,
           t.title,
           t.production_year,
           kt.kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
)
SELECT md.kind                                   AS kind,
       COUNT(*)                                 AS total_movies,
       MIN(md.production_year)                  AS earliest_year,
       MAX(md.production_year)                  AS latest_year,
       AVG(COALESCE(cc.cast_count, 0))          AS avg_cast_per_movie,
       AVG(COALESCE(kc.keyword_count, 0))       AS avg_keywords_per_movie,
       AVG(COALESCE(comc.company_count, 0))     AS avg_companies_per_movie,
       AVG(COALESCE(ic.info_count, 0))          AS avg_info_entries_per_movie
FROM movie_details md
LEFT JOIN cast_counts cc   ON cc.movie_id   = md.movie_id
LEFT JOIN keyword_counts kc ON kc.movie_id   = md.movie_id
LEFT JOIN company_counts comc ON comc.movie_id = md.movie_id
LEFT JOIN info_counts ic    ON ic.movie_id   = md.movie_id
GROUP BY md.kind
ORDER BY total_movies DESC
LIMIT 10
