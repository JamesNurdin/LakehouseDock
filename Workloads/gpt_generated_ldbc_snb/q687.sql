WITH company_gender_stats AS (
    SELECT
        pwc.company_id,
        p.gender,
        COUNT(DISTINCT pwc.person_id) AS employee_count,
        AVG(pwc.work_from) AS avg_work_from
    FROM person_work_at_company pwc
    JOIN person p
        ON pwc.person_id = p.id
    GROUP BY pwc.company_id, p.gender
),
company_totals AS (
    SELECT
        company_id,
        SUM(employee_count) AS total_employees
    FROM company_gender_stats
    GROUP BY company_id
)
SELECT
    cgs.company_id,
    cgs.gender,
    cgs.employee_count,
    cgs.avg_work_from,
    (cgs.employee_count * 100.0) / ct.total_employees AS gender_pct_in_company,
    RANK() OVER (PARTITION BY cgs.company_id ORDER BY cgs.employee_count DESC) AS gender_rank_in_company
FROM company_gender_stats cgs
JOIN company_totals ct
    ON cgs.company_id = ct.company_id
ORDER BY cgs.company_id, gender_rank_in_company
