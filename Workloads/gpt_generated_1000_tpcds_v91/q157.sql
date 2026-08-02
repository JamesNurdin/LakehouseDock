WITH recent_dates AS (
    SELECT
        d_date_sk,
        d_date_id,
        d_date,
        d_year,
        d_day_name,
        d_current_quarter
    FROM date_dim
    WHERE d_date >= DATE '2022-01-01' AND d_date <= DATE '2023-12-31'
),
unioned AS (
    SELECT
        sm.sm_ship_mode_id AS dim_id,
        sm.sm_code AS dim_name,
        rd.d_year AS year,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        'ShipMode' AS source
    FROM catalog_sales cs
    RIGHT OUTER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN recent_dates rd
        ON cs.cs_sold_date_sk = rd.d_date_sk
    WHERE sm.sm_code IN ('AIR', 'SEA')
    GROUP BY sm.sm_ship_mode_id, sm.sm_code, rd.d_year

    UNION

    SELECT
        rd.d_date_id AS dim_id,
        rd.d_day_name AS dim_name,
        rd.d_year AS year,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        'Date' AS source
    FROM catalog_sales cs
    RIGHT OUTER JOIN recent_dates rd
        ON cs.cs_sold_date_sk = rd.d_date_sk
    WHERE rd.d_current_quarter = 'Y'
    GROUP BY rd.d_date_id, rd.d_day_name, rd.d_year
)
SELECT
    dim_id,
    dim_name,
    year,
    total_sales,
    total_profit,
    source,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num
FROM unioned
ORDER BY total_sales DESC, row_num
LIMIT 100
