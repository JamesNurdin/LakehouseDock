WITH ss AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_ext_sales_price
    FROM store_sales ss
),
cs AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_sales_price
    FROM catalog_sales cs
)
SELECT
    d.d_year,
    s.s_store_name,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number)               AS store_sales_transactions,
    SUM(ss.ss_net_profit)                             AS total_store_profit,
    SUM(cs.cs_net_paid)                               AS total_catalog_sales,
    SUM(sr.sr_net_loss)                               AS total_store_returns_loss,
    SUM(cr.cr_net_loss)                               AS total_catalog_returns_loss,
    AVG(i.i_current_price)                            AS avg_item_price,
    MIN(w.w_warehouse_name)                           AS any_warehouse,
    MAX(cc.cc_name)                                   AS any_call_center
FROM ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND i.i_brand = 'Brand#12'
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_url LIKE 'http://%'
    )
GROUP BY d.d_year, s.s_store_name, p.p_promo_name
ORDER BY total_store_profit DESC
LIMIT 100
