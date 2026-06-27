/*
   Analytical query: For each production year and movie kind, compute the number of movies,
   total distinct actors, total distinct keywords, average number of companies per movie,
   and the most frequent keyword for that year‑kind combination.
*/
WITH movie_metrics AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS distinct_actor_cnt,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keyword_cnt,
        COUNT(DISTINCT mc.company_id) AS distinct_company_cnt,
        COUNT(mc.id) AS company_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
keyword_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        k.keyword,
        COUNT(*) AS kw_movie_cnt
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY t.production_year, kt.kind, k.keyword
),
top_keywords AS (
    SELECT
        production_year,
        kind,
        keyword,
        kw_movie_cnt
    FROM (
        SELECT
            production_year,
            kind,
            keyword,
            kw_movie_cnt,
            ROW_NUMBER() OVER (PARTITION BY production_year, kind ORDER BY kw_movie_cnt DESC) AS rn
        FROM keyword_counts
    ) sub
    WHERE rn = 1
)
SELECT
    mm.production_year,
    mm.kind,
    COUNT(*) AS movie_cnt,
    SUM(mm.distinct_actor_cnt) AS total_distinct_actors,
    SUM(mm.distinct_keyword_cnt) AS total_distinct_keywords,
    AVG(mm.company_cnt) AS avg_companies_per_movie,
    tk.keyword AS top_keyword,
    tk.kw_movie_cnt AS top_keyword_movie_count
FROM movie_metrics mm
LEFT JOIN top_keywords tk
    ON mm.production_year = tk.production_year
   AND mm.kind = tk.kind
WHERE mm.production_year IS NOT NULL
GROUP BY mm.production_year, mm.kind, tk.keyword, tk.kw_movie_cnt
ORDER BY mm.production_year DESC, movie_cnt DESC
LIMIT 20
