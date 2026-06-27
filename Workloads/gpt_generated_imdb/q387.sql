WITH cast_counts AS (
    SELECT
        t.id AS title_id,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        COUNT(DISTINCT cn.id) AS num_characters
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id, t.production_year, kt.kind
),
keyword_counts AS (
    SELECT
        t.id AS title_id,
        COUNT(DISTINCT mk.keyword_id) AS num_keywords
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id
)
SELECT
    cc.production_year,
    cc.kind,
    COUNT(DISTINCT cc.title_id) AS num_titles,
    AVG(cc.num_cast) AS avg_cast_per_title,
    AVG(cc.num_characters) AS avg_characters_per_title,
    AVG(kc.num_keywords) AS avg_keywords_per_title
FROM cast_counts cc
JOIN keyword_counts kc ON cc.title_id = kc.title_id
GROUP BY cc.production_year, cc.kind
ORDER BY cc.production_year DESC, cc.kind
