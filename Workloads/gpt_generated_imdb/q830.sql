WITH movie_year_stats AS (
    SELECT
        ct.kind AS company_type,
        CAST(FLOOR(t.production_year) AS integer) AS prod_year,
        COUNT(DISTINCT mc.movie_id) AS movie_cnt,
        COUNT(DISTINCT mc.company_id) AS company_cnt,
        AVG(LENGTH(mc.note)) AS avg_note_len
    FROM movie_companies mc
    JOIN title t
        ON mc.movie_id = t.id
    JOIN company_type ct
        ON mc.company_type_id = ct.id
    WHERE mc.note IS NOT NULL
    GROUP BY ct.kind, CAST(FLOOR(t.production_year) AS integer)
)
SELECT
    company_type,
    prod_year,
    movie_cnt,
    company_cnt,
    avg_note_len,
    RANK() OVER (PARTITION BY company_type ORDER BY movie_cnt DESC) AS year_rank_by_movie_cnt
FROM movie_year_stats
ORDER BY company_type, year_rank_by_movie_cnt
LIMIT 50
