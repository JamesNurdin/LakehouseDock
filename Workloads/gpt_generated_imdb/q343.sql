-- Top‑5 movies per kind (movie, short, tvSeries, …) ranked by number of keywords
--   Includes counts of distinct companies, distinct keywords, and a sample info‑type (id = 5)
--   Uses only the selected IMDB tables and follows all join‑rules.
WITH movie_stats AS (
    SELECT
        t.id                     AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT mc.company_id)                                           AS company_count,
        COUNT(DISTINCT mk.keyword_id)                                           AS keyword_count,
        COUNT(DISTINCT CASE WHEN mi.info_type_id = 5 THEN mi.id END)            AS info_type5_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN movie_keyword   mk ON mk.movie_id = t.id
    LEFT JOIN movie_info      mi ON mi.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
ranked_movies AS (
    SELECT
        kind,
        title,
        production_year,
        company_count,
        keyword_count,
        info_type5_count,
        ROW_NUMBER() OVER (PARTITION BY kind ORDER BY keyword_count DESC, company_count DESC) AS rn
    FROM movie_stats
    WHERE production_year IS NOT NULL
)
SELECT
    kind,
    title,
    production_year,
    company_count,
    keyword_count,
    info_type5_count,
    rn AS rank_within_kind
FROM ranked_movies
WHERE rn <= 5
ORDER BY kind, rn
