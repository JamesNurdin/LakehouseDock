WITH keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
year_kind_agg AS (
    SELECT
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(COALESCE(kc.keyword_cnt, 0)) AS avg_keywords_per_movie
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN keyword_counts kc ON kc.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind
),
company_type_counts AS (
    SELECT
        t.production_year,
        kt.kind,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.movie_id) AS movies_with_company_type
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year, kt.kind, ct.kind
),
top_company_type AS (
    SELECT
        ctc.production_year,
        ctc.kind,
        ctc.company_type,
        ctc.movies_with_company_type,
        ROW_NUMBER() OVER (
            PARTITION BY ctc.production_year, ctc.kind
            ORDER BY ctc.movies_with_company_type DESC
        ) AS rn
    FROM company_type_counts ctc
)
SELECT
    yka.production_year,
    yka.kind,
    yka.movie_count,
    yka.avg_keywords_per_movie,
    tct.company_type AS top_company_type,
    tct.movies_with_company_type AS top_company_type_movie_count
FROM year_kind_agg yka
LEFT JOIN top_company_type tct
    ON yka.production_year = tct.production_year
    AND yka.kind = tct.kind
    AND tct.rn = 1
ORDER BY yka.movie_count DESC
LIMIT 100
