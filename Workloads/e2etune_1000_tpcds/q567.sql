WITH aggregated AS (
    SELECT
        cc.cc_market_manager,
        cc.cc_division_name,
        d_open.d_year AS open_year,
        d_close.d_year AS close_year,
        COUNT(DISTINCT cc.cc_call_center_sk) AS num_call_centers,
        SUM(cc.cc_employees) AS total_employees,
        SUM(cc.cc_sq_ft) AS total_sq_ft,
        AVG(cc.cc_tax_percentage) AS avg_tax_pct,
        ROUND(SUM(cc.cc_employees) * 1.0 / NULLIF(SUM(cc.cc_sq_ft), 0), 4) AS employees_per_sqft
    FROM call_center cc
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close ON cc.cc_closed_date_sk = d_close.d_date_sk
    WHERE
        cc.cc_market_manager IN ('Julius Tran', 'Matthew Clifton')
        AND cc.cc_gmt_offset = -5.00
        AND d_open.d_year BETWEEN 1995 AND 2005
        AND d_close.d_year BETWEEN 2000 AND 2010
        AND cc.cc_county = 'Williamson County'
    GROUP BY
        cc.cc_market_manager,
        cc.cc_division_name,
        d_open.d_year,
        d_close.d_year
    HAVING COUNT(DISTINCT cc.cc_call_center_sk) >= 5
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY cc_market_manager ORDER BY total_employees DESC) AS manager_rank
FROM aggregated
ORDER BY total_employees DESC
LIMIT 100
