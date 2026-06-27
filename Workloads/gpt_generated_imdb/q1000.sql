WITH movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year IS NOT NULL
),
cast_group AS (
    SELECT
        m.kind,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count
    FROM movies m
    JOIN cast_info ci ON ci.movie_id = m.movie_id
    GROUP BY m.kind, m.production_year
),
company_group AS (
    SELECT
        m.kind,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS distinct_company_count
    FROM movies m
    JOIN movie_companies mc ON mc.movie_id = m.movie_id
    GROUP BY m.kind, m.production_year
),
movie_group AS (
    SELECT
        m.kind,
        m.production_year,
        COUNT(DISTINCT m.movie_id) AS movie_count
    FROM movies m
    GROUP BY m.kind, m.production_year
),
keyword_group AS (
    SELECT
        m.kind,
        m.production_year,
        kw.keyword,
        COUNT(*) AS kw_freq
    FROM movies m
    JOIN movie_keyword mk ON mk.movie_id = m.movie_id
    JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY m.kind, m.production_year, kw.keyword
),
keyword_top AS (
    SELECT
        kg.kind,
        kg.production_year,
        kg.keyword,
        kg.kw_freq,
        ROW_NUMBER() OVER (PARTITION BY kg.kind, kg.production_year ORDER BY kg.kw_freq DESC) AS rn
    FROM keyword_group kg
)
SELECT
    mg.kind,
    mg.production_year,
    mg.movie_count,
    COALESCE(cg.distinct_cast_count, 0) AS distinct_cast_members,
    CAST(COALESCE(cg.distinct_cast_count, 0) AS double) / NULLIF(mg.movie_count, 0) AS avg_cast_per_movie,
    COALESCE(compg.distinct_company_count, 0) AS distinct_company_count,
    kt.keyword AS top_keyword,
    kt.kw_freq AS top_keyword_count
FROM movie_group mg
LEFT JOIN cast_group cg
    ON cg.kind = mg.kind AND cg.production_year = mg.production_year
LEFT JOIN company_group compg
    ON compg.kind = mg.kind AND compg.production_year = mg.production_year
LEFT JOIN (
    SELECT kind, production_year, keyword, kw_freq
    FROM keyword_top
    WHERE rn = 1
) kt
    ON kt.kind = mg.kind AND kt.production_year = mg.production_year
ORDER BY mg.kind, mg.production_year
