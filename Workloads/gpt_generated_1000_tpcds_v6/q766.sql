WITH base AS (
    SELECT
        s.s_division_id,
        s.s_division_name,
        s.s_store_sk,
        s.s_number_employees,
        c.cc_tax_percentage,
        c.cc_mkt_id
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN call_center c
        ON c.cc_closed_date_sk = d.d_date_sk
    WHERE s.s_country = 'United States'
      AND s.s_division_id IN (1, 2, 3)
      AND d.d_week_seq BETWEEN 5 AND 20
      AND s.s_gmt_offset >= -5.00
      AND s.s_manager IN ('John Mccoy', 'Joe Johnson')
      AND (c.cc_tax_percentage BETWEEN 0.03 AND 0.07 OR c.cc_tax_percentage IS NULL)
),
aggregated AS (
    SELECT
        s_division_id        AS division_id,
        s_division_name      AS division_name,
        COUNT(DISTINCT s_store_sk)   AS store_count,
        SUM(s_number_employees)      AS total_employees,
        AVG(cc_tax_percentage)       AS avg_tax_pct
    FROM base
    GROUP BY s_division_id, s_division_name
    HAVING COUNT(DISTINCT s_store_sk) >= 2
)
SELECT
    division_id,
    division_name,
    store_count,
    total_employees,
    avg_tax_pct,
    RANK() OVER (ORDER BY total_employees DESC) AS employee_rank
FROM aggregated
ORDER BY employee_rank
LIMIT 100
