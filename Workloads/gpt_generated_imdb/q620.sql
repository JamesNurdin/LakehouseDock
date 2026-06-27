WITH actor_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id
),
company_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        COUNT(DISTINCT ct.kind) AS company_type_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind AS kind,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(cc.company_count, 0) AS company_count,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN actor_counts ac ON t.id = ac.movie_id
LEFT JOIN company_counts cc ON t.id = cc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
WHERE t.production_year >= 2000
ORDER BY actor_count DESC
LIMIT 10
