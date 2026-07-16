WITH date_filter AS (
    SELECT 2450815 AS start_date, 2450825 AS end_date
),
catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_discount_amt) AS catalog_discount,
        SUM(cs.cs_quantity) AS catalog_qty,
        COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales cs
    CROSS JOIN date_filter df
    WHERE cs.cs_sold_date_sk BETWEEN df.start_date AND df.end_date
    GROUP BY cs.cs_bill_customer_sk
),
store_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_discount_amt) AS store_discount,
        SUM(ss.ss_quantity) AS store_qty,
        COUNT(*) AS store_sales_cnt
    FROM store_sales ss
    CROSS JOIN date_filter df
    WHERE ss.ss_sold_date_sk BETWEEN df.start_date AND df.end_date
    GROUP BY ss.ss_customer_sk
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        SUM(ws.ws_quantity) AS web_qty,
        COUNT(*) AS web_sales_cnt
    FROM web_sales ws
    CROSS JOIN date_filter df
    WHERE ws.ws_sold_date_sk BETWEEN df.start_date AND df.end_date
    GROUP BY ws.ws_bill_customer_sk
),
returns_agg AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN (SELECT start_date FROM date_filter) AND (SELECT end_date FROM date_filter)
    GROUP BY sr.sr_customer_sk
),
shipping_mode_agg AS (
    SELECT
        customer_sk,
        sm_type,
        mode_cnt,
        ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY mode_cnt DESC) AS rn
    FROM (
        SELECT
            cs.cs_bill_customer_sk AS customer_sk,
            sm.sm_type,
            COUNT(*) AS mode_cnt
        FROM catalog_sales cs
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        CROSS JOIN date_filter df
        WHERE cs.cs_sold_date_sk BETWEEN df.start_date AND df.end_date
        GROUP BY cs.cs_bill_customer_sk, sm.sm_type

        UNION ALL

        SELECT
            ws.ws_bill_customer_sk AS customer_sk,
            sm.sm_type,
            COUNT(*) AS mode_cnt
        FROM web_sales ws
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        CROSS JOIN date_filter df
        WHERE ws.ws_sold_date_sk BETWEEN df.start_date AND df.end_date
        GROUP BY ws.ws_bill_customer_sk, sm.sm_type
    ) t
)
SELECT
    c.c_customer_id,
    c.c_birth_country,
    COALESCE(ca.catalog_net_profit,0) + COALESCE(sa.store_net_profit,0) + COALESCE(wa.web_net_profit,0) AS total_net_profit,
    COALESCE(ca.catalog_qty,0) + COALESCE(sa.store_qty,0) + COALESCE(wa.web_qty,0) AS total_quantity,
    CASE WHEN (COALESCE(ca.catalog_qty,0) + COALESCE(sa.store_qty,0) + COALESCE(wa.web_qty,0)) > 0
         THEN (COALESCE(ca.catalog_discount,0) + COALESCE(sa.store_discount,0) + COALESCE(wa.web_discount,0))
              / (COALESCE(ca.catalog_qty,0) + COALESCE(sa.store_qty,0) + COALESCE(wa.web_qty,0))
         ELSE 0 END AS avg_discount_per_item,
    COALESCE(ra.total_return_qty,0) AS total_return_quantity,
    CASE WHEN (COALESCE(ca.catalog_qty,0) + COALESCE(sa.store_qty,0) + COALESCE(wa.web_qty,0)) > 0
         THEN COALESCE(ra.total_return_qty,0) * 1.0 /
              (COALESCE(ca.catalog_qty,0) + COALESCE(sa.store_qty,0) + COALESCE(wa.web_qty,0))
         ELSE 0 END AS return_rate,
    sm.sm_type AS preferred_ship_mode
FROM customer c
LEFT JOIN catalog_agg ca ON ca.customer_sk = c.c_customer_sk
LEFT JOIN store_agg sa ON sa.customer_sk = c.c_customer_sk
LEFT JOIN web_agg wa ON wa.customer_sk = c.c_customer_sk
LEFT JOIN returns_agg ra ON ra.customer_sk = c.c_customer_sk
LEFT JOIN (
    SELECT customer_sk, sm_type
    FROM shipping_mode_agg
    WHERE rn = 1
) sm ON sm.customer_sk = c.c_customer_sk
WHERE COALESCE(ca.catalog_net_profit,0) + COALESCE(sa.store_net_profit,0) + COALESCE(wa.web_net_profit,0) > 0
ORDER BY total_net_profit DESC
LIMIT 10
