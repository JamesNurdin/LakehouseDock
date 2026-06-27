/*
  Top information type per production year with yearly movie and info statistics
  Uses only the allowed tables and join relationships.
*/
WITH per_year_info AS (
    SELECT
        t.production_year,
        it.id AS info_type_id,
        it.info AS info_type,
        COUNT(*) AS info_type_cnt
    FROM title t
    JOIN movie_info mi
        ON mi.movie_id = t.id               -- valid join rule
    JOIN info_type it
        ON mi.info_type_id = it.id           -- valid join rule
    GROUP BY t.production_year, it.id, it.info
),
ranked_info AS (
    SELECT
        pyi.*, 
        ROW_NUMBER() OVER (PARTITION BY pyi.production_year ORDER BY pyi.info_type_cnt DESC) AS rn
    FROM per_year_info pyi
)
SELECT
    ri.production_year,
    (
        SELECT COUNT(DISTINCT t2.id)
        FROM title t2
        WHERE t2.production_year = ri.production_year
    ) AS movie_count,
    (
        SELECT COUNT(mi2.id)
        FROM movie_info mi2
        JOIN title t2
            ON mi2.movie_id = t2.id           -- valid join rule
        WHERE t2.production_year = ri.production_year
    ) AS total_info_entries,
    CAST(
        (
            SELECT COUNT(mi2.id)
            FROM movie_info mi2
            JOIN title t2
                ON mi2.movie_id = t2.id       -- valid join rule
            WHERE t2.production_year = ri.production_year
        ) AS double
    ) / NULLIF(
        (
            SELECT COUNT(DISTINCT t2.id)
            FROM title t2
            WHERE t2.production_year = ri.production_year
        ), 0
    ) AS avg_info_per_movie,
    ri.info_type AS top_info_type,
    ri.info_type_cnt AS top_info_type_count
FROM ranked_info ri
WHERE ri.rn = 1
ORDER BY ri.production_year
