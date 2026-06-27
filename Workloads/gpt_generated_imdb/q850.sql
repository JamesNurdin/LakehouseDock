WITH title_info AS (
    SELECT
        t.id,
        t.title,
        CAST(t.production_year AS integer) AS prod_year,
        COUNT(mi.id) AS info_cnt,
        COUNT(DISTINCT mi.info_type_id) AS distinct_info_type_cnt
    FROM title t
    LEFT JOIN movie_info mi
        ON mi.movie_id = t.id
    WHERE CAST(t.production_year AS integer) >= 2000
    GROUP BY t.id, t.title, CAST(t.production_year AS integer)
),
ranked_titles AS (
    SELECT
        prod_year,
        title,
        info_cnt,
        distinct_info_type_cnt,
        RANK() OVER (PARTITION BY prod_year ORDER BY info_cnt DESC) AS rank_in_year
    FROM title_info
)
SELECT
    prod_year,
    title,
    info_cnt,
    distinct_info_type_cnt,
    rank_in_year
FROM ranked_titles
WHERE rank_in_year <= 5
ORDER BY prod_year, rank_in_year
