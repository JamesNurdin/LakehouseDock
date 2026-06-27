WITH rating_info AS (
    SELECT 
        mi.movie_id,
        CAST(mi.info AS double) AS rating_value
    FROM movie_info mi
    JOIN info_type it 
        ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
cast_counts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
)
SELECT 
    t.title,
    t.production_year,
    AVG(r.rating_value) AS avg_rating,
    COUNT(DISTINCT r.rating_value) AS rating_entries,
    cc.cast_count,
    co.company_count,
    kw.keyword_count
FROM title t
JOIN kind_type kt 
    ON t.kind_id = kt.id
LEFT JOIN rating_info r 
    ON r.movie_id = t.id
LEFT JOIN cast_counts cc 
    ON cc.movie_id = t.id
LEFT JOIN company_counts co 
    ON co.movie_id = t.id
LEFT JOIN keyword_counts kw 
    ON kw.movie_id = t.id
WHERE kt.kind = 'movie'
GROUP BY 
    t.title,
    t.production_year,
    cc.cast_count,
    co.company_count,
    kw.keyword_count
HAVING COUNT(DISTINCT r.rating_value) >= 5
ORDER BY avg_rating DESC
LIMIT 10
