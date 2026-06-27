WITH title_metrics AS (
    SELECT
        t.id AS title_id,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast_count,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast_count,
        COUNT(DISTINCT cn.id) AS char_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    LEFT JOIN name n
        ON ci.person_id = n.id
    LEFT JOIN char_name cn
        ON ci.person_role_id = cn.id
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.production_year, kt.kind
)
SELECT
    production_year,
    kind,
    COUNT(*) AS num_titles,
    AVG(cast_count) AS avg_cast_per_title,
    AVG(male_cast_count) AS avg_male_cast_per_title,
    AVG(female_cast_count) AS avg_female_cast_per_title,
    AVG(char_count) AS avg_characters_per_title,
    SUM(keyword_count) AS total_distinct_keywords
FROM title_metrics
GROUP BY production_year, kind
ORDER BY production_year, kind
