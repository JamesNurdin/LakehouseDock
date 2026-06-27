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
cast_agg AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_members
    FROM cast_info ci
    GROUP BY ci.movie_id
),
prod_company_agg AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS prod_companies
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE ct.kind = 'production'
    GROUP BY mc.movie_id
),
keyword_agg AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_cnt
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT
    m.production_year,
    m.kind,
    COUNT(DISTINCT m.movie_id) AS total_movies,
    COALESCE(SUM(ca.cast_members), 0) AS total_cast_members,
    CASE WHEN COUNT(DISTINCT m.movie_id) = 0 THEN 0
         ELSE CAST(SUM(ca.cast_members) AS double) / COUNT(DISTINCT m.movie_id)
    END AS avg_cast_per_movie,
    COALESCE(SUM(pca.prod_companies), 0) AS total_production_companies,
    COALESCE(SUM(ka.keyword_cnt), 0) AS total_keywords
FROM movies m
LEFT JOIN cast_agg ca ON m.movie_id = ca.movie_id
LEFT JOIN prod_company_agg pca ON m.movie_id = pca.movie_id
LEFT JOIN keyword_agg ka ON m.movie_id = ka.movie_id
GROUP BY
    m.production_year,
    m.kind
ORDER BY
    m.production_year ASC,
    m.kind
