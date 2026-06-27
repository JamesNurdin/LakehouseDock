WITH student_by_place AS (
    SELECT
        COALESCE(parent.id, p.id) AS place_id,
        COALESCE(parent.name, p.name) AS place_name,
        COUNT(DISTINCT ps.person_id) AS student_cnt
    FROM person_study_at_university ps
    JOIN organisation o
        ON ps.university_id = o.id
    JOIN place p
        ON o.location_place_id = p.id
    LEFT JOIN place parent
        ON p.part_of_place_id = parent.id
    GROUP BY
        COALESCE(parent.id, p.id),
        COALESCE(parent.name, p.name)
),
worker_by_place AS (
    SELECT
        COALESCE(parent.id, p.id) AS place_id,
        COALESCE(parent.name, p.name) AS place_name,
        COUNT(DISTINCT pw.person_id) AS worker_cnt
    FROM person_work_at_company pw
    JOIN organisation o
        ON pw.company_id = o.id
    JOIN place p
        ON o.location_place_id = p.id
    LEFT JOIN place parent
        ON p.part_of_place_id = parent.id
    GROUP BY
        COALESCE(parent.id, p.id),
        COALESCE(parent.name, p.name)
)
SELECT
    COALESCE(s.place_id, w.place_id) AS place_id,
    COALESCE(s.place_name, w.place_name) AS place_name,
    s.student_cnt,
    w.worker_cnt,
    CASE
        WHEN w.worker_cnt > 0 THEN s.student_cnt * 1.0 / w.worker_cnt
        ELSE NULL
    END AS student_to_worker_ratio
FROM student_by_place s
FULL OUTER JOIN worker_by_place w
    ON s.place_id = w.place_id
ORDER BY student_cnt DESC NULLS LAST
