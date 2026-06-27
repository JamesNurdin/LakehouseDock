WITH movie_ratings AS (
    SELECT
        mi.movie_id,
        AVG(CAST(mi.info AS double)) AS rating
    FROM movie_info mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
    GROUP BY mi.movie_id
)
SELECT
    kt.kind AS kind,
    COUNT(DISTINCT t.id) AS total_titles,
    AVG(t.production_year) AS avg_production_year,
    COUNT(DISTINCT ci.person_id) AS distinct_cast_members,
    COUNT(DISTINCT mc.company_id) AS distinct_companies,
    COUNT(DISTINCT mk.keyword_id) AS distinct_keywords,
    AVG(r.rating) AS avg_rating
FROM title t
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN cast_info ci
    ON ci.movie_id = t.id
LEFT JOIN movie_companies mc
    ON mc.movie_id = t.id
LEFT JOIN movie_keyword mk
    ON mk.movie_id = t.id
LEFT JOIN movie_ratings r
    ON r.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY kt.kind
ORDER BY total_titles DESC
LIMIT 20
