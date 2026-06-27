WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title AS title,
        t.production_year AS production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind = 'production') AS num_production_companies,
        AVG(mi_idx.note) FILTER (WHERE mi_idx.info_type_id = 101) AS avg_rating,
        COUNT(DISTINCT mk.keyword_id) AS num_keywords
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_info_idx mi_idx ON mi_idx.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE kt.kind = 'movie'
      AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.title, t.production_year, kt.kind
)
SELECT
    movie_id,
    title,
    production_year,
    kind,
    num_cast,
    num_production_companies,
    avg_rating,
    num_keywords
FROM movie_stats
ORDER BY num_cast DESC
LIMIT 10
