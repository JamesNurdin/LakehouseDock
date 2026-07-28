WITH
    store_sales_agg AS (
        SELECT
            ss_customer_sk,
            ss_promo_sk,
            SUM(ss_net_paid) AS total_store_sales,
            COUNT(*)        AS cnt_store_txn
        FROM store_sales
        GROUP BY ss_customer_sk, ss_promo_sk
    ),
    returns_agg AS (
        SELECT
            wr_refunded_customer_sk,
            wr_order_number,
            SUM(wr_return_amt) AS total_return_amount,
            COUNT(*)           AS cnt_returns
        FROM web_returns
        GROUP BY wr_refunded_customer_sk, wr_order_number
    )
SELECT
    p.p_promo_name,
    sm_ws.sm_type               AS ship_mode_type,
    SUM(ssa.total_store_sales)  AS store_sales_total,
    SUM(ws.ws_net_paid)         AS web_sales_total,
    SUM(cs.cs_net_paid)         AS catalog_sales_total,
    SUM(ra.total_return_amount) AS returns_total,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
FROM store_sales_agg ssa
JOIN customer c               ON ssa.ss_customer_sk = c.c_customer_sk
JOIN promotion p               ON ssa.ss_promo_sk = p.p_promo_sk
LEFT JOIN web_sales ws        ON ssa.ss_customer_sk = ws.ws_bill_customer_sk
                              AND ssa.ss_promo_sk = ws.ws_promo_sk
LEFT JOIN catalog_sales cs    ON ssa.ss_customer_sk = cs.cs_bill_customer_sk
                              AND ssa.ss_promo_sk = cs.cs_promo_sk
LEFT JOIN ship_mode sm_ws      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN ship_mode sm_cs      ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
LEFT JOIN web_page wp_ws       ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
LEFT JOIN web_site wsite       ON ws.ws_web_site_sk = wsite.web_site_sk
LEFT JOIN web_returns wr       ON ws.ws_order_number = wr.wr_order_number
LEFT JOIN returns_agg ra       ON ra.wr_refunded_customer_sk = wr.wr_refunded_customer_sk
                              AND ra.wr_order_number = wr.wr_order_number
LEFT JOIN web_page wp_wr       ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_order_number = ws.ws_order_number
      AND wr2.wr_return_amt > 0
)
GROUP BY p.p_promo_name, sm_ws.sm_type
ORDER BY store_sales_total DESC
LIMIT 100
