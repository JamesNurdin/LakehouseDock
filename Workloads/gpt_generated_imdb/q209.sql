WITH rating_info AS (
    SELECT mi.movie_id,
           CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
cast_counts AS (
    SELECT ci.movie_id,
           COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT mk.movie_id,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT k.kind AS kind,
       t.production_year,
       COUNT(*) AS num_movies,
       AVG(r.rating) AS avg_rating,
       AVG(c.cast_count) AS avg_cast_per_movie,
       AVG(kw.keyword_count) AS avg_keywords_per_movie
FROM title t
JOIN kind_type k ON t.kind_id = k.id
LEFT JOIN rating_info r ON r.movie_id = t.id
LEFT JOIN cast_counts c ON c.movie_id = t.id
LEFT JOIN keyword_counts kw ON kw.movie_id = t.id
WHERE t.production_year IS NOT NULL
GROUP BY k.kind, t.production_year
ORDER BY k.kind, t.production_year DESC
LIMIT 100
