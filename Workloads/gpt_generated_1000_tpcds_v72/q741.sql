WITH catalog_sales_agg AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        sm.sm_type AS ship_mode,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        'catalog' AS source
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
    GROUP BY hd.hd_demo_sk, sm.sm_type
    HAVING SUM(cs.cs_ext_sales_price) > 10000
),
web_sales_agg AS (
    SELECT
        hd.hd_demo_sk AS demo_sk,
        sm.sm_type AS ship_mode,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        'web' AS source
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
    GROUP BY hd.hd_demo_sk, sm.sm_type
    HAVING SUM(ws.ws_ext_sales_price) > 10000
),
combined AS (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
)
SELECT
    source,
    demo_sk,
    ship_mode,
    sales_amount
FROM combined
ORDER BY sales_amount DESC
LIMIT 100
