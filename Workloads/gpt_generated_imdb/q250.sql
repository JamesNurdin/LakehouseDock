WITH movie_cast AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS distinct_cast,
        COUNT(DISTINCT ci.person_role_id) AS distinct_roles
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_company AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS distinct_companies,
        COUNT(DISTINCT CASE WHEN ct.kind = 'production' THEN mc.company_id END) AS production_companies
    FROM title t
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE t.production_year >= 2000
    GROUP BY t.id
),
movie_keyword AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keywords
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    GROUP BY t.id
)
SELECT
    mc.title,
    mc.production_year,
    mc.kind,
    mc.distinct_cast,
    mc.distinct_roles,
    co.distinct_companies,
    co.production_companies,
    kw.distinct_keywords
FROM movie_cast mc
LEFT JOIN movie_company co ON mc.movie_id = co.movie_id
LEFT JOIN movie_keyword kw ON mc.movie_id = kw.movie_id
ORDER BY mc.distinct_cast DESC
LIMIT 10
