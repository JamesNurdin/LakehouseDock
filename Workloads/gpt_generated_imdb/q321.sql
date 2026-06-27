WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        COUNT(DISTINCT mk.keyword_id) AS num_keywords,
        COUNT(DISTINCT mi.info_type_id) AS num_info_types
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    num_actors,
    num_companies,
    num_keywords,
    num_info_types,
    (num_actors + num_companies + num_keywords + num_info_types) AS total_distinct_attributes
FROM movie_stats
WHERE production_year >= 2000
ORDER BY total_distinct_attributes DESC, num_actors DESC
LIMIT 10
