SELECT
    state,
    quarter,
    store_cnt,
    total_floor_space,
    avg_tax_percentage,
    min_employees,
    max_employees
FROM (
    SELECT
        s.s_state AS state,
        d.d_quarter_name AS quarter,
        COUNT(s.s_store_sk) AS store_cnt,
        SUM(s.s_floor_space) AS total_floor_space,
        AVG(s.s_tax_percentage) AS avg_tax_percentage,
        MIN(s.s_number_employees) AS min_employees,
        MAX(s.s_number_employees) AS max_employees
    FROM store s
    CROSS JOIN LATERAL (
        SELECT dd.d_quarter_name,
               dd.d_current_week,
               dd.d_date_sk
        FROM date_dim dd
        WHERE dd.d_date_sk = s.s_closed_date_sk
    ) AS d
    WHERE s.s_company_id = 1
      AND s.s_state = 'CA'
      AND d.d_quarter_name = '1904Q4'
      AND EXISTS (
          SELECT 1
          FROM date_dim d2
          WHERE d2.d_date_sk = s.s_closed_date_sk
            AND d2.d_current_week = 'N'
      )
    GROUP BY s.s_state, d.d_quarter_name

    UNION ALL

    SELECT
        s.s_state AS state,
        d.d_quarter_name AS quarter,
        COUNT(s.s_store_sk) AS store_cnt,
        SUM(s.s_floor_space) AS total_floor_space,
        AVG(s.s_tax_percentage) AS avg_tax_percentage,
        MIN(s.s_number_employees) AS min_employees,
        MAX(s.s_number_employees) AS max_employees
    FROM store s
    CROSS JOIN LATERAL (
        SELECT dd.d_quarter_name,
               dd.d_current_week,
               dd.d_date_sk
        FROM date_dim dd
        WHERE dd.d_date_sk = s.s_closed_date_sk
    ) AS d
    WHERE s.s_company_id = 1
      AND s.s_state = 'TX'
      AND s.s_street_name = 'Washington'
      AND d.d_quarter_name = '1903Q4'
      AND d.d_current_week = 'N'
    GROUP BY s.s_state, d.d_quarter_name
) AS combined
LIMIT 100
