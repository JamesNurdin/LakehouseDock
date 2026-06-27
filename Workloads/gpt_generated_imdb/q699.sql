WITH role_counts AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        cn.id AS role_id,
        cn.name AS role_name,
        COUNT(*) AS role_appearances,
        AVG(ci.nr_order) AS avg_nr_order
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY n.id, n.name, cn.id, cn.name
),
ranked_roles AS (
    SELECT
        person_id,
        person_name,
        role_id,
        role_name,
        role_appearances,
        avg_nr_order,
        ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY role_appearances DESC) AS role_rank
    FROM role_counts
)
SELECT
    person_id,
    person_name,
    role_id,
    role_name,
    role_appearances,
    avg_nr_order
FROM ranked_roles
WHERE role_rank <= 3
ORDER BY person_name, role_rank
