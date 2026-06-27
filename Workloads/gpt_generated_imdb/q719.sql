WITH role_movie_char_counts AS (
    SELECT
        t.production_year,
        ci.role_id,
        t.id AS movie_id,
        COUNT(DISTINCT cn.id) AS char_count
    FROM
        cast_info ci
        JOIN title t ON ci.movie_id = t.id
        JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE
        t.production_year >= 2000
        AND t.kind_id = 1
    GROUP BY
        t.production_year,
        ci.role_id,
        t.id
)
SELECT
    rmc.production_year,
    rmc.role_id,
    COUNT(DISTINCT rmc.movie_id) AS movie_count,
    AVG(rmc.char_count) AS avg_characters_per_movie,
    MAX(rmc.char_count) AS max_characters_in_movie,
    MIN(rmc.char_count) AS min_characters_in_movie
FROM
    role_movie_char_counts rmc
GROUP BY
    rmc.production_year,
    rmc.role_id
ORDER BY
    rmc.production_year,
    rmc.role_id
