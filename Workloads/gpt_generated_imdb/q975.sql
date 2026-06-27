WITH keyword_counts AS (
    SELECT
        t.production_year,
        k.keyword,
        COUNT(DISTINCT mk.movie_id) AS movie_count
    FROM
        title t
        JOIN kind_type kt ON t.kind_id = kt.id
        JOIN movie_keyword mk ON mk.movie_id = t.id
        JOIN keyword k ON k.id = mk.keyword_id
        JOIN movie_info mi ON mi.movie_id = t.id
        JOIN info_type it ON it.id = mi.info_type_id
    WHERE
        kt.kind = 'movie'
        AND t.production_year IS NOT NULL
        AND it.info = 'runtime'
        AND try_cast(mi.info AS integer) > 90
    GROUP BY
        t.production_year,
        k.keyword
),
ranked_keywords AS (
    SELECT
        production_year,
        keyword,
        movie_count,
        row_number() OVER (PARTITION BY production_year ORDER BY movie_count DESC) AS rn
    FROM
        keyword_counts
)
SELECT
    production_year,
    keyword,
    movie_count
FROM
    ranked_keywords
WHERE
    rn <= 3
ORDER BY
    production_year,
    movie_count DESC
