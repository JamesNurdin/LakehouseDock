WITH movie_metrics AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS distinct_male_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS distinct_female_cast,
        COUNT(DISTINCT mc.company_id) AS distinct_company_count,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keyword_count,
        COUNT(DISTINCT cn.id) AS distinct_character_count
    FROM title t
    LEFT JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN name n ON ci.person_id = n.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
)

SELECT
    production_year,
    kind,
    COUNT(*) AS movie_count,
    SUM(distinct_cast_count) AS total_distinct_cast,
    AVG(distinct_cast_count) AS avg_cast_per_movie,
    SUM(distinct_male_cast) AS total_male_cast,
    SUM(distinct_female_cast) AS total_female_cast,
    SUM(distinct_company_count) AS total_distinct_companies,
    AVG(distinct_keyword_count) AS avg_keywords_per_movie,
    SUM(distinct_character_count) AS total_distinct_characters
FROM movie_metrics
WHERE production_year IS NOT NULL
GROUP BY production_year, kind
ORDER BY production_year DESC, movie_count DESC
LIMIT 20
