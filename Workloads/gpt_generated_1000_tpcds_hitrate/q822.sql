WITH base AS (
    SELECT
        c.c_customer_id,
        cc.cc_market_manager,
        cs.cs_order_number,
        cs.cs_net_profit,
        ss.ss_net_paid,
        w.w_warehouse_sq_ft
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_mkt_id IN (2, 5)
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND c.c_birth_month = 5
      AND NOT EXISTS (
            SELECT 1 FROM store_sales ss2
            WHERE ss2.ss_ticket_number = cs.cs_order_number
              AND ss2.ss_quantity > 10
        )
    UNION
    SELECT
        c.c_customer_id,
        cc.cc_market_manager,
        cs.cs_order_number,
        cs.cs_net_profit,
        ss.ss_net_paid,
        w.w_warehouse_sq_ft
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_mkt_desc LIKE '%areas%'
      AND cc.cc_gmt_offset BETWEEN -5.00 AND 2.00
      AND c.c_last_review_date BETWEEN 2452310 AND 2452600
      AND NOT EXISTS (
            SELECT 1 FROM store_sales ss2
            WHERE ss2.ss_ticket_number = cs.cs_order_number
              AND ss2.ss_quantity > 10
        )
)
SELECT
    base.c_customer_id,
    base.cc_market_manager,
    CASE WHEN base.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
    SUM(base.cs_net_profit) AS total_profit,
    AVG(base.ss_net_paid) AS avg_store_paid,
    COUNT(DISTINCT base.cs_order_number) AS order_cnt,
    MAX(base.w_warehouse_sq_ft) AS max_warehouse_sq_ft,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS overall_avg_profit
FROM base
GROUP BY
    base.c_customer_id,
    base.cc_market_manager,
    CASE WHEN base.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END
HAVING SUM(base.cs_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
