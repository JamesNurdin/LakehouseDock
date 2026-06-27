WITH cast_counts AS (
    SELECT movie_id, count(*) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
keyword_counts AS (
    SELECT movie_id, count(*) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
),
info_counts AS (
    SELECT movie_id, count(*) AS info_count
    FROM movie_info
    GROUP BY movie_id
),
info_idx_counts AS (
    SELECT movie_id, count(*) AS info_idx_count
    FROM movie_info_idx
    GROUP BY movie_id
),
company_counts AS (
    SELECT movie_id, count(DISTINCT company_id) AS company_count
    FROM movie_companies
    GROUP BY movie_id
)
SELECT
    kt.kind AS kind,
    count(DISTINCT t.id) AS total_movies,
    avg(coalesce(cc.cast_count, 0)) AS avg_cast_per_movie,
    avg(coalesce(kc.keyword_count, 0)) AS avg_keywords_per_movie,
    avg(coalesce(ic.info_count, 0)) AS avg_info_entries_per_movie,
    avg(coalesce(iic.info_idx_count, 0)) AS avg_info_idx_entries_per_movie,
    avg(coalesce(compc.company_count, 0)) AS avg_companies_per_movie
FROM title t
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN info_counts ic ON t.id = ic.movie_id
LEFT JOIN info_idx_counts iic ON t.id = iic.movie_id
LEFT JOIN company_counts compc ON t.id = compc.movie_id
JOIN kind_type kt ON t.kind_id = kt.id
WHERE t.production_year >= 2000
GROUP BY kt.kind
ORDER BY total_movies DESC
LIMIT 10
