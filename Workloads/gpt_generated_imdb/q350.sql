WITH movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        kt.kind AS kind,
        t.production_year
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    WHERE t.production_year >= 2000
),
actor_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
character_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT chn.name) AS character_count
    FROM cast_info ci
    LEFT JOIN char_name chn ON ci.person_role_id = chn.id
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS distinct_company_name_count,
        SUM(CASE WHEN ct.kind = 'production' THEN 1 ELSE 0 END) AS production_company_count,
        SUM(CASE WHEN ct.kind = 'distribution' THEN 1 ELSE 0 END) AS distribution_company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT
    m.movie_id,
    m.title,
    m.kind,
    m.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(cc.character_count, 0) AS character_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(compc.distinct_company_name_count, 0) AS distinct_company_name_count,
    COALESCE(compc.production_company_count, 0) AS production_company_count,
    COALESCE(compc.distribution_company_count, 0) AS distribution_company_count
FROM movies m
LEFT JOIN actor_counts ac ON ac.movie_id = m.movie_id
LEFT JOIN character_counts cc ON cc.movie_id = m.movie_id
LEFT JOIN keyword_counts kc ON kc.movie_id = m.movie_id
LEFT JOIN company_counts compc ON compc.movie_id = m.movie_id
ORDER BY actor_count DESC
LIMIT 100
