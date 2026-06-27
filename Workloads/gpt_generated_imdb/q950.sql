WITH
    movie_stats AS (
        SELECT
            ci.person_id,
            COUNT(DISTINCT ci.movie_id) AS movie_count,
            MIN(t.production_year) AS earliest_year,
            MAX(t.production_year) AS latest_year,
            AVG(t.production_year) AS avg_year
        FROM cast_info ci
        JOIN title t ON ci.movie_id = t.id
        WHERE t.production_year >= 2000
        GROUP BY ci.person_id
    ),
    company_stats AS (
        SELECT
            ci.person_id,
            COUNT(DISTINCT mc.company_id) AS distinct_company_count
        FROM cast_info ci
        JOIN title t ON ci.movie_id = t.id
        JOIN movie_companies mc ON mc.movie_id = t.id
        GROUP BY ci.person_id
    ),
    role_stats AS (
        SELECT
            ci.person_id,
            COUNT(DISTINCT cn.id) AS distinct_role_count
        FROM cast_info ci
        JOIN char_name cn ON ci.person_role_id = cn.id
        GROUP BY ci.person_id
    ),
    alias_stats AS (
        SELECT
            an.person_id,
            COUNT(DISTINCT an.id) AS alias_count
        FROM aka_name an
        GROUP BY an.person_id
    ),
    info_stats AS (
        SELECT
            pi.person_id,
            COUNT(*) AS info_entries
        FROM person_info pi
        GROUP BY pi.person_id
    )
SELECT
    n.id,
    n.name,
    n.gender,
    COALESCE(ms.movie_count, 0) AS movie_count,
    COALESCE(ms.earliest_year, 0) AS earliest_year,
    COALESCE(ms.latest_year, 0) AS latest_year,
    COALESCE(ms.avg_year, 0) AS avg_year,
    COALESCE(cs.distinct_company_count, 0) AS distinct_company_count,
    COALESCE(rs.distinct_role_count, 0) AS distinct_role_count,
    COALESCE(al.alias_count, 0) AS alias_count,
    COALESCE(inf.info_entries, 0) AS info_entries
FROM name n
LEFT JOIN movie_stats ms ON ms.person_id = n.id
LEFT JOIN company_stats cs ON cs.person_id = n.id
LEFT JOIN role_stats rs ON rs.person_id = n.id
LEFT JOIN alias_stats al ON al.person_id = n.id
LEFT JOIN info_stats inf ON inf.person_id = n.id
WHERE n.gender IS NOT NULL
  AND COALESCE(ms.movie_count, 0) >= 5
ORDER BY movie_count DESC, n.name
LIMIT 100
