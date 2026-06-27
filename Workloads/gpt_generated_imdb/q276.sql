WITH joined_data AS (
    SELECT
        ci.id AS cast_id,
        ci.person_id,
        ci.movie_id,
        ci.person_role_id,
        ci.note,
        ci.nr_order,
        ci.role_id,
        cn.id AS char_id,
        cn.name,
        cn.imdb_index,
        cn.imdb_id,
        cn.name_pcode_nf,
        cn.surname_pcode,
        cn.md5sum
    FROM
        cast_info ci
    JOIN
        char_name cn
        ON ci.person_role_id = cn.id
)
SELECT
    name,
    imdb_index,
    COUNT(DISTINCT movie_id) AS distinct_movie_count,
    COUNT(DISTINCT role_id) AS distinct_role_count,
    AVG(nr_order) AS avg_nr_order,
    MIN(nr_order) AS min_nr_order,
    MAX(nr_order) AS max_nr_order
FROM
    joined_data
GROUP BY
    name,
    imdb_index
HAVING
    COUNT(DISTINCT movie_id) >= 5
ORDER BY
    distinct_movie_count DESC,
    avg_nr_order DESC
