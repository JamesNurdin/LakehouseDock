WITH title_stats AS (
    SELECT
        t.id,
        t.production_year,
        kt.kind AS kind,
        (
            SELECT COUNT(DISTINCT ci.person_id)
            FROM cast_info ci
            WHERE ci.movie_id = t.id
        ) AS cast_count,
        (
            SELECT COUNT(DISTINCT kw.keyword)
            FROM movie_keyword mk
            JOIN keyword kw ON mk.keyword_id = kw.id
            WHERE mk.movie_id = t.id
        ) AS keyword_count,
        (
            SELECT COUNT(DISTINCT cn.id)
            FROM movie_companies mc
            JOIN company_type ct ON mc.company_type_id = ct.id
            JOIN company_name cn ON mc.company_id = cn.id
            WHERE mc.movie_id = t.id
              AND ct.kind = 'production'
        ) AS prod_company_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
)
SELECT
    ts.production_year,
    ts.kind,
    COUNT(DISTINCT ts.id) AS num_titles,
    AVG(ts.cast_count) AS avg_cast_per_title,
    AVG(ts.keyword_count) AS avg_keywords_per_title,
    AVG(ts.prod_company_count) AS avg_prod_companies_per_title
FROM title_stats ts
WHERE ts.production_year >= 2000
GROUP BY ts.production_year, ts.kind
ORDER BY ts.production_year DESC, ts.kind
