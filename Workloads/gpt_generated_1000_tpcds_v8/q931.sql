WITH diff_customers AS (
        SELECT ss_customer_sk
        FROM store_sales
        EXCEPT
        SELECT ws_bill_customer_sk
        FROM web_sales
    ),
    intersect_promos AS (
        SELECT ss_promo_sk
        FROM store_sales
        INTERSECT
        SELECT ws_promo_sk
        FROM web_sales
    ),
    full_sales_returns AS (
        SELECT
            ss.*, 
            sr.sr_returned_date_sk,
            sr.sr_customer_sk   AS sr_customer_sk,
            sr.sr_hdemo_sk      AS sr_hdemo_sk,
            sr.sr_addr_sk       AS sr_addr_sk,
            sr.sr_store_sk      AS sr_store_sk,
            sr.sr_reason_sk,
            sr.sr_net_loss
        FROM store_sales ss
        FULL OUTER JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
    )
SELECT
    c.c_customer_id,
    s.s_state,
    ca.ca_state,
    r.r_reason_desc,
    SUM(COALESCE(fsr.ss_net_profit, 0) - COALESCE(fsr.sr_net_loss, 0))                     AS total_net_profit,
    COUNT(DISTINCT c.c_customer_sk)                                                       AS distinct_customers,
    AVG(fsr.ss_quantity)                                                                  AS avg_quantity,
    MIN(cr.cr_refunded_cash)                                                              AS min_refunded_cash,
    MAX(cr.cr_refunded_cash)                                                              AS max_refunded_cash,
    CASE WHEN SUM(COALESCE(fsr.ss_net_profit, 0) - COALESCE(fsr.sr_net_loss, 0)) > (
            SELECT AVG(ss_net_profit) FROM store_sales
        )
        THEN 'Above Avg'
        ELSE 'Below Avg'
    END                                                                                  AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(COALESCE(fsr.ss_net_profit, 0) - COALESCE(fsr.sr_net_loss, 0)) DESC) AS rn_state,
    (SELECT COUNT(*) FROM diff_customers)                                                AS diff_customer_cnt,
    (SELECT COUNT(*) FROM intersect_promos)                                              AS intersect_promo_cnt
FROM full_sales_returns fsr
JOIN customer c
    ON c.c_customer_sk = COALESCE(fsr.ss_customer_sk, fsr.sr_customer_sk)
JOIN household_demographics hd
    ON hd.hd_demo_sk = COALESCE(fsr.ss_hdemo_sk, fsr.sr_hdemo_sk)
JOIN income_band ib
    ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN customer_address ca
    ON ca.ca_address_sk = COALESCE(fsr.ss_addr_sk, fsr.sr_addr_sk)
JOIN store s
    ON s.s_store_sk = COALESCE(fsr.ss_store_sk, fsr.sr_store_sk)
LEFT JOIN promotion p
    ON p.p_promo_sk = fsr.ss_promo_sk
LEFT JOIN reason r
    ON r.r_reason_sk = fsr.sr_reason_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
LEFT JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
LEFT JOIN warehouse w
    ON w.w_warehouse_sk = cr.cr_warehouse_sk
LEFT JOIN reason r2
    ON r2.r_reason_sk = cr.cr_reason_sk
LEFT JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_bill_hdemo_sk    = hd.hd_demo_sk
   AND ws.ws_bill_addr_sk     = ca.ca_address_sk
   AND ws.ws_promo_sk         = p.p_promo_sk
WHERE s.s_state = 'CA'
  AND ca.ca_state = 'TX'
  AND r.r_reason_id = 'AAAAAAAACAAAAAAA'
  AND p.p_channel_email = 'Y'
  AND fsr.ss_sold_date_sk BETWEEN 2451910 AND 2452000
  AND ws.ws_ship_date_sk = 2451915
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
    )
GROUP BY CUBE(s.s_state, ca.ca_state, r.r_reason_desc), c.c_customer_id
ORDER BY total_net_profit DESC
LIMIT 100
