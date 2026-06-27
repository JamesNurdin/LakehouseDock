WITH rating_by_movie AS (
    SELECT mi.movie_id,
           avg(mi.note) AS avg_rating
    FROM movie_info_idx mi
    JOIN info_type it
      ON mi.info_type_id = it.id
    WHERE it.info = 'rating' 
      AND mi.note IS NOT NULL
    GROUP BY mi.movie_id
),
actor_counts_by_movie AS (
    SELECT ci.movie_id,
           count(DISTINCT ci.person_id) AS actor_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts_by_movie AS (
    SELECT mk.movie_id,
           count(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
company_counts_by_movie AS (
    SELECT mc.movie_id,
           count(DISTINCT CASE WHEN ct.kind = 'production company' THEN mc.company_id END) AS prod_company_cnt,
           count(DISTINCT CASE WHEN ct.kind = 'distribution' THEN mc.company_id END) AS dist_company_cnt
    FROM movie_companies mc
    JOIN company_type ct
      ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
movie_stats AS (
    SELECT t.id,
           t.production_year,
           kt.kind,
           r.avg_rating,
           a.actor_cnt,
           k.keyword_cnt,
           c.prod_company_cnt,
           c.dist_company_cnt
    FROM title t
    JOIN kind_type kt
      ON t.kind_id = kt.id
    LEFT JOIN rating_by_movie r
      ON t.id = r.movie_id
    LEFT JOIN actor_counts_by_movie a
      ON t.id = a.movie_id
    LEFT JOIN keyword_counts_by_movie k
      ON t.id = k.movie_id
    LEFT JOIN company_counts_by_movie c
      ON t.id = c.movie_id
    WHERE t.production_year IS NOT NULL
),
keyword_freq AS (
    SELECT t.production_year,
           kt.kind,
           kw.keyword,
           count(*) AS kw_cnt
    FROM title t
    JOIN kind_type kt
      ON t.kind_id = kt.id
    JOIN movie_keyword mk
      ON t.id = mk.movie_id
    JOIN keyword kw
      ON mk.keyword_id = kw.id
    GROUP BY t.production_year, kt.kind, kw.keyword
),
top_keyword AS (
    SELECT production_year,
           kind,
           keyword,
           kw_cnt,
           row_number() OVER (PARTITION BY production_year, kind ORDER BY kw_cnt DESC) AS rn
    FROM keyword_freq
)
SELECT ms.production_year,
       ms.kind,
       count(*) AS movie_cnt,
       avg(ms.avg_rating) AS avg_rating,
       sum(ms.actor_cnt) AS total_actors,
       sum(ms.keyword_cnt) AS total_keywords,
       sum(ms.prod_company_cnt) AS total_production_companies,
       sum(ms.dist_company_cnt) AS total_distribution_companies,
       tk.keyword AS top_keyword,
       tk.kw_cnt AS top_keyword_count
FROM movie_stats ms
LEFT JOIN top_keyword tk
  ON ms.production_year = tk.production_year
 AND ms.kind = tk.kind
 AND tk.rn = 1
GROUP BY ms.production_year, ms.kind, tk.keyword, tk.kw_cnt
ORDER BY ms.production_year DESC, avg_rating DESC
LIMIT 50
