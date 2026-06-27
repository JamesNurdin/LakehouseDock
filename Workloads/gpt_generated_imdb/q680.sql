WITH person_aka_info AS (
    SELECT
        n.gender,
        it.info AS info_type,
        an.name AS aka_name,
        n.id AS person_id
    FROM name n
    JOIN person_info pi ON pi.person_id = n.id
    JOIN info_type it ON pi.info_type_id = it.id
    JOIN aka_name an ON an.person_id = n.id
),
person_counts AS (
    SELECT
        gender,
        info_type,
        COUNT(DISTINCT person_id) AS total_person_cnt
    FROM person_aka_info
    GROUP BY gender, info_type
),
aka_counts AS (
    SELECT
        gender,
        info_type,
        aka_name,
        COUNT(DISTINCT person_id) AS person_cnt
    FROM person_aka_info
    GROUP BY gender, info_type, aka_name
),
ranked_aka AS (
    SELECT
        a.gender,
        a.info_type,
        a.aka_name,
        a.person_cnt,
        t.total_person_cnt,
        ROW_NUMBER() OVER (PARTITION BY a.gender, a.info_type ORDER BY a.person_cnt DESC) AS rn
    FROM aka_counts a
    JOIN person_counts t
        ON a.gender = t.gender AND a.info_type = t.info_type
)
SELECT
    gender,
    info_type,
    aka_name,
    person_cnt,
    total_person_cnt,
    CAST(person_cnt AS DOUBLE) / total_person_cnt AS proportion
FROM ranked_aka
WHERE rn = 1
ORDER BY gender, person_cnt DESC
