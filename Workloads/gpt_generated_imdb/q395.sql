WITH movie_stats AS (
    SELECT
        t.id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT CASE WHEN mi.info_type_id = 101 THEN mi.info END) AS rating_count
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    WHERE t.production_year >= 2000
      AND kt.kind = 'movie'
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    id,
    title,
    production_year,
    kind,
    cast_count,
    company_count,
    keyword_count,
    rating_count
FROM movie_stats
ORDER BY cast_count DESC
LIMIT 100
