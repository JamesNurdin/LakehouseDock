WITH company_agg AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS distinct_company_cnt
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_agg AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT k.id) AS distinct_keyword_cnt
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
info_agg AS (
    SELECT mi.movie_id,
           AVG(mi.note) AS avg_note
    FROM movie_info_idx mi
    GROUP BY mi.movie_id
)
SELECT
    t.production_year,
    t.kind_id,
    COUNT(*) AS movie_cnt,
    AVG(COALESCE(ca.distinct_company_cnt, 0)) AS avg_companies_per_movie,
    AVG(COALESCE(ka.distinct_keyword_cnt, 0)) AS avg_keywords_per_movie,
    AVG(ia.avg_note) AS avg_note_per_movie
FROM title t
LEFT JOIN company_agg ca ON t.id = ca.movie_id
LEFT JOIN keyword_agg ka ON t.id = ka.movie_id
LEFT JOIN info_agg ia ON t.id = ia.movie_id
WHERE t.production_year BETWEEN 2000 AND 2020
  AND t.kind_id = 1
GROUP BY t.production_year, t.kind_id
ORDER BY t.production_year ASC, t.kind_id ASC
