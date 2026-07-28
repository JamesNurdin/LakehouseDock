WITH sales_agg AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_ext_sales_price) AS cat_sales,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        COUNT(DISTINCT cs.cs_order_number) AS cat_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        AVG(cs.cs_net_profit) AS avg_cat_profit,
        AVG(ss.ss_net_profit) AS avg_store_profit,
        AVG(ws.ws_net_profit) AS avg_web_profit
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE
        cp.cp_type = 'catalog'
        AND ss.ss_ext_wholesale_cost > 1000.00
        AND ib.ib_upper_bound <= 120000
        AND ws.ws_quantity >= 2
        AND cs.cs_sold_date_sk BETWEEN 2451088 AND 2451210
        AND NOT EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_bill_hdemo_sk = hd.hd_demo_sk
              AND ws2.ws_coupon_amt > 0
        )
    GROUP BY
        GROUPING SETS (
            (hd.hd_demo_sk, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound),
            (ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound),
            ()
        )
),
zero_sales AS (
    SELECT DISTINCT
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CAST(0 AS decimal(15,2)) AS cat_sales,
        CAST(0 AS decimal(15,2)) AS store_sales,
        CAST(0 AS decimal(15,2)) AS web_sales,
        0 AS cat_orders,
        0 AS store_tickets,
        0 AS web_orders,
        CAST(NULL AS double) AS avg_cat_profit,
        CAST(NULL AS double) AS avg_store_profit,
        CAST(NULL AS double) AS avg_web_profit
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM catalog_sales cs
        WHERE cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    )
)
SELECT *
FROM (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM zero_sales
) AS combined
ORDER BY ib_income_band_sk, hd_demo_sk
LIMIT 100
