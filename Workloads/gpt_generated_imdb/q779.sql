WITH movie_agg AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT IF(ct.kind = 'production', cn.id, NULL)) AS production_company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    GROUP BY t.id, t.production_year, kt.kind
)
SELECT
    production_year,
    kind,
    COUNT(*) AS total_movies,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(production_company_count) AS avg_production_companies_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    AVG(info_type_count) AS avg_info_types_per_movie
FROM movie_agg
WHERE production_year IS NOT NULL
GROUP BY production_year, kind
ORDER BY production_year, kind
