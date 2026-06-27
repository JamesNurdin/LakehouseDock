WITH cast_per_movie AS (
    SELECT ci.movie_id,
           count(DISTINCT ci.person_id) AS cast_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_per_movie AS (
    SELECT mc.movie_id,
           count(DISTINCT mc.company_id) AS comp_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_per_movie AS (
    SELECT mk.movie_id,
           k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
),
keyword_counts AS (
    SELECT t.production_year,
           t.kind_id,
           kp.keyword,
           count(*) AS keyword_cnt
    FROM title t
    JOIN keyword_per_movie kp ON kp.movie_id = t.id
    WHERE t.production_year IS NOT NULL
      AND t.production_year >= 2000
    GROUP BY t.production_year,
             t.kind_id,
             kp.keyword
),
top_keyword_per_group AS (
    SELECT kc.production_year,
           kc.kind_id,
           kc.keyword,
           kc.keyword_cnt,
           row_number() OVER (PARTITION BY kc.production_year, kc.kind_id ORDER BY kc.keyword_cnt DESC) AS rn
    FROM keyword_counts kc
),
movie_metrics AS (
    SELECT t.production_year,
           t.kind_id,
           count(DISTINCT t.id) AS total_movies,
           avg(cp.cast_cnt) AS avg_cast_per_movie,
           avg(cm.comp_cnt) AS avg_companies_per_movie
    FROM title t
    LEFT JOIN cast_per_movie cp ON cp.movie_id = t.id
    LEFT JOIN company_per_movie cm ON cm.movie_id = t.id
    WHERE t.production_year IS NOT NULL
      AND t.production_year >= 2000
    GROUP BY t.production_year,
             t.kind_id
)
SELECT mm.production_year,
       mm.kind_id,
       mm.total_movies,
       mm.avg_cast_per_movie,
       mm.avg_companies_per_movie,
       tk.keyword AS top_keyword,
       tk.keyword_cnt AS top_keyword_count
FROM movie_metrics mm
LEFT JOIN (
    SELECT production_year,
           kind_id,
           keyword,
           keyword_cnt
    FROM top_keyword_per_group
    WHERE rn = 1
) tk
ON tk.production_year = mm.production_year
   AND tk.kind_id = mm.kind_id
ORDER BY mm.production_year DESC, mm.kind_id
