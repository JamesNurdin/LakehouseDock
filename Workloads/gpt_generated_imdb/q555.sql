-- Average cast, characters, keywords, companies, and person‑info types per movie by production year
WITH movie_stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT cn.id) AS character_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT pi.info_type_id) AS person_info_type_count
    FROM title t
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN char_name cn
        ON ci.person_role_id = cn.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN name n
        ON ci.person_id = n.id
    LEFT JOIN person_info pi
        ON pi.person_id = n.id
    GROUP BY t.id, t.title, t.production_year
)
SELECT
    production_year,
    COUNT(*) AS movie_count,
    AVG(cast_count) AS avg_cast_per_movie,
    AVG(character_count) AS avg_characters_per_movie,
    AVG(keyword_count) AS avg_keywords_per_movie,
    AVG(company_count) AS avg_companies_per_movie,
    AVG(person_info_type_count) AS avg_person_info_types_per_movie
FROM movie_stats
WHERE production_year IS NOT NULL
GROUP BY production_year
ORDER BY production_year
