WITH movie_cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE kt.kind = 'movie'
    GROUP BY ci.movie_id
),
movie_keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT
    mc.company_id,
    mc.company_type_id,
    t.production_year,
    COUNT(DISTINCT t.id) AS num_movies,
    SUM(mcc.cast_count) AS total_cast_members,
    AVG(mcc.cast_count) AS avg_cast_per_movie,
    SUM(COALESCE(mkc.keyword_count, 0)) AS total_keywords,
    AVG(COALESCE(mkc.keyword_count, 0)) AS avg_keywords_per_movie
FROM movie_companies mc
JOIN title t ON mc.movie_id = t.id
JOIN kind_type kt2 ON t.kind_id = kt2.id
JOIN movie_cast_counts mcc ON t.id = mcc.movie_id
LEFT JOIN movie_keyword_counts mkc ON t.id = mkc.movie_id
WHERE kt2.kind = 'movie'
  AND t.production_year IS NOT NULL
GROUP BY mc.company_id, mc.company_type_id, t.production_year
ORDER BY mc.company_id, mc.company_type_id, t.production_year
