WITH cast_agg AS (
        SELECT
            ci.movie_id,
            COUNT(*) AS cast_count,
            COUNT(DISTINCT ci.person_id) AS distinct_actor_count,
            COUNT(DISTINCT ci.person_role_id) AS distinct_character_count
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    company_agg AS (
        SELECT
            mc.movie_id,
            COUNT(DISTINCT cn.id) AS production_company_count
        FROM movie_companies mc
        JOIN company_type ct ON mc.company_type_id = ct.id
        JOIN company_name cn ON mc.company_id = cn.id
        WHERE ct.kind = 'production company'
        GROUP BY mc.movie_id
    ),
    keyword_agg AS (
        SELECT
            mk.movie_id,
            COUNT(DISTINCT k.keyword) AS keyword_count
        FROM movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
        GROUP BY mk.movie_id
    ),
    rating_agg AS (
        SELECT
            mi.movie_id,
            AVG(CAST(mi.info AS DOUBLE)) AS avg_rating
        FROM movie_info mi
        JOIN info_type it ON mi.info_type_id = it.id
        WHERE it.info = 'rating'
        GROUP BY mi.movie_id
    )
SELECT
    t.title,
    t.production_year,
    kt.kind AS kind,
    COALESCE(ca.cast_count, 0) AS cast_count,
    COALESCE(ca.distinct_actor_count, 0) AS distinct_actor_count,
    COALESCE(ca.distinct_character_count, 0) AS distinct_character_count,
    COALESCE(compa.production_company_count, 0) AS production_company_count,
    COALESCE(kw.keyword_count, 0) AS keyword_count,
    ra.avg_rating
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_agg ca ON ca.movie_id = t.id
LEFT JOIN company_agg compa ON compa.movie_id = t.id
LEFT JOIN keyword_agg kw ON kw.movie_id = t.id
LEFT JOIN rating_agg ra ON ra.movie_id = t.id
WHERE kt.kind = 'movie'
ORDER BY cast_count DESC
LIMIT 10
