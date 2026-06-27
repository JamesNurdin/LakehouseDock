WITH mk_join AS (
    SELECT
        mk.id AS mk_id,
        mk.movie_id,
        mk.keyword_id AS mk_keyword_id,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        kw.id AS keyword_id,
        kw.keyword AS keyword_text
    FROM movie_keyword mk
    JOIN title t
        ON mk.movie_id = t.id
    JOIN keyword kw
        ON mk.keyword_id = kw.id
    WHERE t.kind_id = 1
      AND t.production_year IS NOT NULL
)
SELECT
    kj.keyword_id,
    kj.keyword_text,
    COUNT(DISTINCT kj.title_id) AS movie_count,
    AVG(kj.production_year) AS avg_production_year,
    MIN(kj.production_year) AS earliest_production_year,
    MAX(kj.production_year) AS latest_production_year,
    slice(array_agg(kj.movie_title ORDER BY kj.production_year DESC), 1, 5) AS top_5_recent_titles
FROM mk_join kj
GROUP BY kj.keyword_id, kj.keyword_text
ORDER BY movie_count DESC
LIMIT 20
