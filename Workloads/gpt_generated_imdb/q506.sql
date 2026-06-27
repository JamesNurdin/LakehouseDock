WITH keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(*) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
info_counts AS (
    SELECT mi.movie_id,
           COUNT(*) AS info_cnt
    FROM movie_info mi
    GROUP BY mi.movie_id
)
SELECT
    cn.name AS company_name,
    cn.country_code,
    ct.kind AS company_type,
    t.production_year,
    COUNT(DISTINCT t.id) AS movie_count,
    AVG(COALESCE(kc.keyword_cnt, 0)) AS avg_keywords_per_movie,
    AVG(COALESCE(ic.info_cnt, 0)) AS avg_info_entries_per_movie
FROM movie_companies mc
JOIN title t
  ON mc.movie_id = t.id
JOIN company_name cn
  ON mc.company_id = cn.id
JOIN company_type ct
  ON mc.company_type_id = ct.id
LEFT JOIN keyword_counts kc
  ON t.id = kc.movie_id
LEFT JOIN info_counts ic
  ON t.id = ic.movie_id
WHERE ct.kind = 'production company'
  AND t.production_year IS NOT NULL
GROUP BY cn.name, cn.country_code, ct.kind, t.production_year
ORDER BY movie_count DESC
LIMIT 100
