WITH employee_info AS (
    SELECT
        PW.person_id,
        PW.company_id,
        PW.work_from,
        P.gender
    FROM person_work_at_company PW
    JOIN person P
        ON PW.person_id = P.id
)
SELECT
    O.type AS organisation_type,
    O.name AS organisation_name,
    EI.gender,
    COUNT(DISTINCT EI.person_id) AS employee_count,
    AVG(EI.work_from) AS avg_work_from,
    MIN(EI.work_from) AS min_work_from,
    MAX(EI.work_from) AS max_work_from
FROM employee_info EI
JOIN organisation O
    ON EI.company_id = O.id
GROUP BY O.type, O.name, EI.gender
ORDER BY employee_count DESC
