WITH cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS comp_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS kw_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_detail AS (
    SELECT t.id               AS movie_id,
           t.title,
           t.production_year,
           kt.kind
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
      AND t.production_year >= 2000
),
movie_stats AS (
    SELECT md.movie_id,
           md.production_year,
           md.kind,
           COALESCE(cc.cast_cnt, 0)   AS cast_cnt,
           COALESCE(compc.comp_cnt, 0) AS comp_cnt,
           COALESCE(kc.kw_cnt, 0)    AS kw_cnt
    FROM movie_detail md
    LEFT JOIN cast_counts cc      ON md.movie_id = cc.movie_id
    LEFT JOIN company_counts compc ON md.movie_id = compc.movie_id
    LEFT JOIN keyword_counts kc   ON md.movie_id = kc.movie_id
),
year_kind_stats AS (
    SELECT ms.production_year,
           ms.kind,
           COUNT(*)                         AS num_movies,
           AVG(ms.cast_cnt)                 AS avg_cast_per_movie,
           AVG(ms.comp_cnt)                 AS avg_companies_per_movie,
           AVG(ms.kw_cnt)                   AS avg_keywords_per_movie
    FROM movie_stats ms
    GROUP BY ms.production_year, ms.kind
),
year_kind_actors AS (
    SELECT t.production_year,
           kt.kind,
           COUNT(DISTINCT ci.person_id) AS distinct_actors
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
      AND t.production_year >= 2000
    GROUP BY t.production_year, kt.kind
)
SELECT yks.production_year,
       yks.kind,
       yks.num_movies,
       yks.avg_cast_per_movie,
       yks.avg_companies_per_movie,
       yks.avg_keywords_per_movie,
       yka.distinct_actors
FROM year_kind_stats yks
LEFT JOIN year_kind_actors yka
       ON yks.production_year = yka.production_year
      AND yks.kind = yka.kind
ORDER BY yks.production_year DESC, yks.kind
