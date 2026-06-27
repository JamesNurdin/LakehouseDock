WITH rating_notes AS (
    SELECT
        mk.keyword_id,
        t.id AS movie_id,
        t.production_year,
        mi.note AS rating
    FROM movie_keyword mk
    JOIN title t
        ON mk.movie_id = t.id
    JOIN movie_info_idx mi
        ON mi.movie_id = t.id
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
      AND t.production_year IS NOT NULL
)
SELECT
    keyword_id,
    COUNT(DISTINCT movie_id) AS movie_count,
    AVG(rating) AS avg_rating,
    AVG(production_year) AS avg_production_year
FROM rating_notes
GROUP BY keyword_id
ORDER BY avg_rating DESC
LIMIT 10
