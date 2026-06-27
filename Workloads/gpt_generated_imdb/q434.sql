WITH person_roles AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender,
        COUNT(*) AS role_count,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(t.production_year) AS avg_production_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    GROUP BY n.id, n.name, n.gender
),
aka_counts AS (
    SELECT
        an.person_id,
        COUNT(*) AS aka_count
    FROM aka_name an
    GROUP BY an.person_id
),
person_info_counts AS (
    SELECT
        pi.person_id,
        COUNT(*) AS info_count
    FROM person_info pi
    GROUP BY pi.person_id
),
char_counts AS (
    SELECT
        ci.person_id,
        cn.name AS character_name,
        COUNT(*) AS char_role_count
    FROM cast_info ci
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY ci.person_id, cn.name
),
top_char AS (
    SELECT
        cc.person_id,
        cc.character_name,
        cc.char_role_count
    FROM (
        SELECT
            cc.*,
            ROW_NUMBER() OVER (PARTITION BY cc.person_id ORDER BY cc.char_role_count DESC) AS rn
        FROM char_counts cc
    ) cc
    WHERE cc.rn = 1
)
SELECT
    pr.person_id,
    pr.person_name,
    pr.gender,
    pr.role_count,
    pr.movie_count,
    pr.avg_production_year,
    COALESCE(ac.aka_count, 0) AS aka_count,
    COALESCE(pic.info_count, 0) AS info_count,
    tc.character_name,
    tc.char_role_count
FROM person_roles pr
LEFT JOIN aka_counts ac ON pr.person_id = ac.person_id
LEFT JOIN person_info_counts pic ON pr.person_id = pic.person_id
LEFT JOIN top_char tc ON pr.person_id = tc.person_id
ORDER BY pr.role_count DESC
LIMIT 10
