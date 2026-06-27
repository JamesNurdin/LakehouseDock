WITH rating_per_movie AS (
    SELECT mi.movie_id,
           MAX(TRY_CAST(mi.info AS double)) AS rating
    FROM movie_info_idx mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
),
keywords_per_movie AS (
    SELECT movie_id,
           COUNT(DISTINCT keyword_id) AS kw_cnt
    FROM movie_keyword
    GROUP BY movie_id
)
SELECT
    n.id AS person_id,
    n.name AS person_name,
    n.gender,
    COUNT(DISTINCT t.id) AS total_movies,
    COUNT(DISTINCT cn.name) AS distinct_characters,
    AVG(rpm.rating) AS avg_rating,
    SUM(kpm.kw_cnt) AS total_keywords,
    ARRAY_AGG(DISTINCT an.name) FILTER (WHERE an.name IS NOT NULL) AS alt_names
FROM cast_info ci
JOIN name n ON ci.person_id = n.id
LEFT JOIN char_name cn ON ci.person_role_id = cn.id
JOIN title t ON ci.movie_id = t.id
LEFT JOIN rating_per_movie rpm ON t.id = rpm.movie_id
LEFT JOIN keywords_per_movie kpm ON t.id = kpm.movie_id
LEFT JOIN aka_name an ON n.id = an.person_id
WHERE t.kind_id = 1
  AND t.production_year >= 2000
  AND EXISTS (
      SELECT 1
      FROM movie_companies mc
      WHERE mc.movie_id = t.id
        AND mc.company_type_id = 1
  )
GROUP BY n.id, n.name, n.gender
ORDER BY avg_rating DESC NULLS LAST
LIMIT 10
