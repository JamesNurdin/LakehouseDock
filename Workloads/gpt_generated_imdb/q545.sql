WITH movies AS (
    SELECT id,
           title,
           kind_id,
           production_year
    FROM title
    WHERE production_year >= 2000
),
cast_counts AS (
    SELECT movie_id,
           COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
company_counts AS (
    SELECT movie_id,
           COUNT(DISTINCT company_id) AS company_count
    FROM movie_companies
    GROUP BY movie_id
),
keyword_counts AS (
    SELECT movie_id,
           COUNT(DISTINCT keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
),
info_counts AS (
    SELECT movie_id,
           COUNT(DISTINCT info_type_id) AS info_type_count
    FROM movie_info
    GROUP BY movie_id
),
movie_metrics AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           kt.kind AS kind,
           COALESCE(cc.cast_count, 0)        AS cast_count,
           COALESCE(compc.company_count, 0) AS company_count,
           COALESCE(kc.keyword_count, 0)    AS keyword_count,
           COALESCE(ic.info_type_count, 0)  AS info_type_count
    FROM movies m
    LEFT JOIN cast_counts cc      ON cc.movie_id      = m.id
    LEFT JOIN company_counts compc ON compc.movie_id  = m.id
    LEFT JOIN keyword_counts kc   ON kc.movie_id      = m.id
    LEFT JOIN info_counts ic      ON ic.movie_id      = m.id
    LEFT JOIN kind_type kt        ON kt.id            = m.kind_id
)
SELECT kind,
       COUNT(*)                             AS movie_count,
       AVG(cast_count)                      AS avg_cast_per_movie,
       AVG(company_count)                   AS avg_companies_per_movie,
       AVG(keyword_count)                   AS avg_keywords_per_movie,
       AVG(info_type_count)                 AS avg_info_types_per_movie
FROM movie_metrics
GROUP BY kind
ORDER BY movie_count DESC
LIMIT 10
