WITH store_sales_agg AS (
    SELECT
        d.d_year AS sales_year,
        'Store' AS sales_channel,
        SUM(ss.ss_net_profit) AS total_net_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 1000000 THEN 'High' ELSE 'Medium' END AS profit_category
    FROM store_sales ss
    CROSS JOIN LATERAL (
        SELECT d_year
        FROM date_dim d
        WHERE d.d_date_sk = ss.ss_sold_date_sk
    ) d
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_county = 'Huron County'
      AND s.s_rec_start_date >= DATE '2001-01-01'
      AND d.d_year BETWEEN 2000 AND 2005
    GROUP BY d.d_year
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS sales_year,
        'Catalog' AS sales_channel,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 1000000 THEN 'High' ELSE 'Medium' END AS profit_category
    FROM catalog_sales cs
    CROSS JOIN LATERAL (
        SELECT d_year
        FROM date_dim d
        WHERE d.d_date_sk = cs.cs_sold_date_sk
    ) d
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'FEDX'
      AND d.d_year BETWEEN 2000 AND 2005
    GROUP BY d.d_year
)
SELECT
    sales_year,
    sales_channel,
    total_net_profit,
    profit_category
FROM store_sales_agg
UNION ALL
SELECT
    sales_year,
    sales_channel,
    total_net_profit,
    profit_category
FROM catalog_sales_agg
ORDER BY sales_year, sales_channel, total_net_profit DESC
LIMIT 100
