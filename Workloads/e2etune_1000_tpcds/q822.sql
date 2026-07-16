WITH closed_store_events AS (
    SELECT
        s.s_state AS state,
        d.d_moy AS month,
        d.d_quarter_name AS quarter,
        s.s_floor_space AS floor_space,
        s.s_tax_percentage AS tax_percentage,
        s.s_number_employees AS number_employees,
        CASE
            WHEN s.s_floor_space < 5000 THEN 'Small'
            WHEN s.s_floor_space BETWEEN 5000 AND 20000 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM store s
    JOIN date_dim d
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1900 AND 1904
      AND d.d_current_quarter = 'Y'
      AND d.d_weekend = 'N'
      AND s.s_tax_percentage > 0
),
aggregated AS (
    SELECT
        state,
        month,
        quarter,
        size_category,
        SUM(floor_space) AS total_floor_space_closed,
        AVG(tax_percentage) AS avg_tax_pct,
        COUNT(*) AS stores_closed,
        SUM(number_employees) AS total_employees
    FROM closed_store_events
    GROUP BY GROUPING SETS (
        (state, month, quarter, size_category),
        (state, month, quarter),
        (state, month),
        (state),
        (month),
        ()
    )
)
SELECT
    state,
    month,
    quarter,
    size_category,
    total_floor_space_closed,
    avg_tax_pct,
    stores_closed,
    total_employees,
    SUM(total_floor_space_closed) OVER (PARTITION BY state ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_floor_space_state,
    RANK() OVER (ORDER BY total_floor_space_closed DESC) AS floor_space_rank
FROM aggregated
ORDER BY total_floor_space_closed DESC
LIMIT 200
