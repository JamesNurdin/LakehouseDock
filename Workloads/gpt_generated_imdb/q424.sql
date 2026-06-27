WITH
    cast_agg AS (
        SELECT
            ci.movie_id,
            COUNT(DISTINCT ci.person_id) AS cast_count
        FROM cast_info ci
        JOIN title t ON ci.movie_id = t.id
        GROUP BY ci.movie_id
    ),
    company_agg AS (
        SELECT
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM movie_companies mc
        JOIN title t ON mc.movie_id = t.id
        GROUP BY mc.movie_id
    ),
    keyword_agg AS (
        SELECT
            mk.movie_id,
            COUNT(DISTINCT mk.keyword_id) AS keyword_count
        FROM movie_keyword mk
        JOIN title t ON mk.movie_id = t.id
        GROUP BY mk.movie_id
    ),
    info_agg AS (
        SELECT
            mi.movie_id,
            COUNT(DISTINCT mi.info_type_id) AS info_type_count
        FROM movie_info mi
        JOIN title t ON mi.movie_id = t.id
        GROUP BY mi.movie_id
    ),
    title_base AS (
        SELECT
            t.id AS movie_id,
            t.title,
            t.production_year,
            kt.kind
        FROM title t
        JOIN kind_type kt ON t.kind_id = kt.id
    )
SELECT
    tb.kind,
    tb.production_year,
    COUNT(DISTINCT tb.movie_id) AS movie_count,
    COALESCE(SUM(ca.cast_count), 0) AS total_cast_members,
    COALESCE(SUM(coa.company_count), 0) AS total_companies,
    COALESCE(SUM(ka.keyword_count), 0) AS total_keywords,
    COALESCE(SUM(ia.info_type_count), 0) AS total_info_types,
    CASE WHEN COUNT(DISTINCT tb.movie_id) = 0 THEN 0
         ELSE SUM(COALESCE(ca.cast_count, 0)) / COUNT(DISTINCT tb.movie_id)
    END AS avg_cast_per_movie
FROM title_base tb
LEFT JOIN cast_agg ca   ON tb.movie_id = ca.movie_id
LEFT JOIN company_agg coa ON tb.movie_id = coa.movie_id
LEFT JOIN keyword_agg ka  ON tb.movie_id = ka.movie_id
LEFT JOIN info_agg ia     ON tb.movie_id = ia.movie_id
GROUP BY tb.kind, tb.production_year
ORDER BY movie_count DESC
LIMIT 10
