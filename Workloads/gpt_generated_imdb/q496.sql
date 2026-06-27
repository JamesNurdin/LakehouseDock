WITH cast_agg AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT n.id) AS distinct_cast_members,
        COUNT(DISTINCT ch.id) AS distinct_characters,
        COUNT(DISTINCT CASE WHEN n.gender = 'M' THEN n.id END) AS male_cast,
        COUNT(DISTINCT CASE WHEN n.gender = 'F' THEN n.id END) AS female_cast,
        AVG(cn.nr_order) AS avg_cast_order
    FROM title t
    JOIN cast_info cn ON cn.movie_id = t.id
    JOIN name n ON n.id = cn.person_id
    LEFT JOIN char_name ch ON ch.id = cn.person_role_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
),
aka_agg AS (
    SELECT
        t.id AS title_id,
        COUNT(DISTINCT an.id) AS distinct_aka_names
    FROM title t
    JOIN cast_info cn ON cn.movie_id = t.id
    JOIN name n ON n.id = cn.person_id
    JOIN aka_name an ON an.person_id = n.id
    WHERE t.production_year >= 2000
    GROUP BY t.id
),
info_agg AS (
    SELECT
        t.id AS title_id,
        it.info AS info_type,
        COUNT(DISTINCT pi.person_id) AS person_info_count
    FROM title t
    JOIN cast_info cn ON cn.movie_id = t.id
    JOIN name n ON n.id = cn.person_id
    JOIN person_info pi ON pi.person_id = n.id
    JOIN info_type it ON it.id = pi.info_type_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, it.info
)
SELECT
    ca.title_id,
    ca.title,
    ca.production_year,
    ca.distinct_cast_members,
    ca.distinct_characters,
    ca.male_cast,
    ca.female_cast,
    COALESCE(ak.distinct_aka_names, 0) AS distinct_aka_names,
    ca.avg_cast_order,
    ia.info_type,
    ia.person_info_count
FROM cast_agg ca
LEFT JOIN aka_agg ak ON ak.title_id = ca.title_id
LEFT JOIN info_agg ia ON ia.title_id = ca.title_id
ORDER BY ca.distinct_cast_members DESC
LIMIT 20
