WITH keyword_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        k.keyword,
        COUNT(DISTINCT t.id) AS movie_cnt
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.production_year, kt.kind, k.keyword
)
SELECT
    qc.production_year,
    qc.kind,
    qc.keyword,
    qc.movie_cnt
FROM (
    SELECT
        production_year,
        kind,
        keyword,
        movie_cnt,
        ROW_NUMBER() OVER (PARTITION BY production_year, kind ORDER BY movie_cnt DESC) AS rn
    FROM keyword_counts
) qc
WHERE qc.rn <= 5
ORDER BY qc.production_year DESC, qc.kind, qc.rn
