/*
  Top movies (released from 2010 onward) ranked by the number of distinct cast members.
  For each movie we also list its kind (e.g., "movie"), production year and the full list of associated keywords.
*/
WITH movie_cast_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        array_agg(DISTINCT k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind,
    mc.cast_count,
    kw.keywords
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN movie_cast_counts mc ON mc.movie_id = t.id
LEFT JOIN movie_keywords kw ON kw.movie_id = t.id
WHERE t.production_year >= 2010
  AND kt.kind = 'movie'
ORDER BY mc.cast_count DESC
LIMIT 20
