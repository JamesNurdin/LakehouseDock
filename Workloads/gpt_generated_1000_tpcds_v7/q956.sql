WITH catalog_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        'catalog' AS channel,
        sm.sm_carrier AS carrier,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_weekend = 'Y'
      AND d.d_year = 2002
    GROUP BY d.d_date, sm.sm_carrier
),
store_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        'store' AS channel,
        CAST(NULL AS varchar) AS carrier,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_weekend = 'N'
      AND d.d_year = 2002
    GROUP BY d.d_date
)
SELECT sale_date, channel, carrier, total_net_paid_inc_tax
FROM catalog_sales_agg
UNION ALL
SELECT sale_date, channel, carrier, total_net_paid_inc_tax
FROM store_sales_agg
ORDER BY sale_date, channel
