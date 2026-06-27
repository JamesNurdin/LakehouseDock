WITH movie_year_counts AS (
    SELECT
        mi.info_type_id,
        t.production_year,
        COUNT(DISTINCT mi.movie_id) AS movie_cnt_year
    FROM movie_info mi
    JOIN title t
        ON mi.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY mi.info_type_id, t.production_year
),
movie_total_counts AS (
    SELECT
        mi.info_type_id,
        COUNT(DISTINCT mi.movie_id) AS total_movie_cnt
    FROM movie_info mi
    GROUP BY mi.info_type_id
),
person_counts AS (
    SELECT
        pi.info_type_id,
        COUNT(DISTINCT pi.person_id) AS person_cnt
    FROM person_info pi
    GROUP BY pi.info_type_id
)
SELECT
    it.info AS info_type,
    myc.production_year,
    myc.movie_cnt_year,
    mtc.total_movie_cnt,
    pc.person_cnt
FROM movie_year_counts myc
JOIN movie_total_counts mtc
    ON myc.info_type_id = mtc.info_type_id
JOIN person_counts pc
    ON myc.info_type_id = pc.info_type_id
JOIN info_type it
    ON myc.info_type_id = it.id
WHERE myc.production_year >= 2000
ORDER BY mtc.total_movie_cnt DESC, it.info, myc.production_year
