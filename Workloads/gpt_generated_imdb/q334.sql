WITH cast_agg AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT ci.person_role_id) AS character_count,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN ci.person_id END) AS male_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN ci.person_id END) AS female_cast
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    GROUP BY ci.movie_id
),
company_agg AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mc.company_type_id) AS company_type_count
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
keyword_agg AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT
    t.title,
    t.production_year,
    kt.kind AS kind,
    COALESCE(ca.cast_count, 0) AS cast_count,
    COALESCE(ca.character_count, 0) AS character_count,
    COALESCE(ca.male_cast, 0) AS male_cast,
    COALESCE(ca.female_cast, 0) AS female_cast,
    COALESCE(compa.company_count, 0) AS company_count,
    COALESCE(compa.company_type_count, 0) AS company_type_count,
    COALESCE(ka.keyword_count, 0) AS keyword_count
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_agg ca ON t.id = ca.movie_id
LEFT JOIN company_agg compa ON t.id = compa.movie_id
LEFT JOIN keyword_agg ka ON t.id = ka.movie_id
WHERE t.production_year >= 2000
ORDER BY cast_count DESC, t.production_year DESC
LIMIT 100
