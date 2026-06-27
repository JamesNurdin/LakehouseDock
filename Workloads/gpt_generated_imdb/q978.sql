WITH rating AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
)
SELECT
    t.title,
    t.production_year,
    kt.kind AS kind,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    COUNT(DISTINCT cn.id) AS distinct_character_count,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COUNT(DISTINCT ct.kind) AS distinct_company_type_count,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    AVG(r.rating) AS avg_rating
FROM title t
JOIN kind_type kt
    ON t.kind_id = kt.id
LEFT JOIN cast_info ci
    ON ci.movie_id = t.id
LEFT JOIN char_name cn
    ON ci.person_role_id = cn.id
LEFT JOIN movie_companies mc
    ON mc.movie_id = t.id
LEFT JOIN company_type ct
    ON mc.company_type_id = ct.id
LEFT JOIN movie_keyword mk
    ON mk.movie_id = t.id
LEFT JOIN rating r
    ON r.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY t.title, t.production_year, kt.kind
HAVING AVG(r.rating) IS NOT NULL
ORDER BY avg_rating DESC
LIMIT 100
