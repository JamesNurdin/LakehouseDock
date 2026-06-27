WITH movie_stats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT cn.id) AS character_count
    FROM title t
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    keyword_count,
    character_count,
    (cast_count + keyword_count + character_count) AS total_score
FROM (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        keyword_count,
        character_count,
        ROW_NUMBER() OVER (
            PARTITION BY production_year 
            ORDER BY (cast_count + keyword_count + character_count) DESC
        ) AS rn
    FROM movie_stats
) ranked
WHERE rn <= 5
ORDER BY production_year, total_score DESC
