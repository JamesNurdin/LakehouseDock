WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        MAX(CASE WHEN it.info = 'rating' THEN CAST(mi.info AS double) END) AS rating,
        MAX(CASE WHEN it.info = 'votes' THEN CAST(mi.info AS double) END) AS votes,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    rating,
    votes,
    cast_count,
    keyword_count,
    company_count
FROM movie_stats
WHERE rating IS NOT NULL
ORDER BY rating DESC
LIMIT 20
