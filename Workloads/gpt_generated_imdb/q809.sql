WITH keyword_year_stats AS (
    SELECT
        k.keyword,
        t.production_year,
        COUNT(DISTINCT mk.movie_id) AS movie_cnt,
        COUNT(DISTINCT mc.company_id) AS company_cnt,
        AVG(mi.note) AS avg_note
    FROM title t
    JOIN movie_keyword mk
        ON mk.movie_id = t.id
    JOIN keyword k
        ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc
        ON mc.movie_id = t.id
    LEFT JOIN movie_info_idx mi
        ON mi.movie_id = t.id
        AND mi.info_type_id = 101
    WHERE t.kind_id = 1
      AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY k.keyword, t.production_year
),
ranked_keywords AS (
    SELECT
        keyword,
        production_year,
        movie_cnt,
        company_cnt,
        avg_note,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_cnt DESC) AS rn
    FROM keyword_year_stats
)
SELECT
    keyword,
    production_year,
    movie_cnt,
    company_cnt,
    avg_note
FROM ranked_keywords
WHERE rn <= 5
ORDER BY production_year, movie_cnt DESC
