WITH ss_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_paid_inc_tax,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        ARRAY[ss.ss_quantity, ss.ss_quantity] AS qty_arr
    FROM store_sales ss
    WHERE ss.ss_net_paid > 1000
      AND ss.ss_quantity >= 2
      AND ss.ss_store_sk IS NOT NULL
      AND ss.ss_promo_sk IS NOT NULL
),
ss_unnested AS (
    SELECT
        ss_base.*,
        q AS qty_item
    FROM ss_base
    CROSS JOIN UNNEST(ss_base.qty_arr) AS t(q)
)
SELECT
    s.s_state,
    p.p_promo_name,
    r.r_reason_desc,
    COUNT(DISTINCT ss_unnested.ss_ticket_number) AS orders_cnt,
    SUM(ss_unnested.ss_net_paid) AS total_net_paid,
    AVG(ss_unnested.ss_quantity) AS avg_quantity,
    MIN(i.inv_quantity_on_hand) AS min_inventory,
    MAX(ws.ws_net_paid) AS max_web_net_paid
FROM ss_unnested
JOIN store_returns sr
    ON sr.sr_ticket_number = ss_unnested.ss_ticket_number
JOIN store s
    ON s.s_store_sk = ss_unnested.ss_store_sk
JOIN promotion p
    ON p.p_promo_sk = ss_unnested.ss_promo_sk
JOIN customer c
    ON c.c_customer_sk = ss_unnested.ss_customer_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = c.c_current_hdemo_sk
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN call_center cc
    ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON r.r_reason_sk = sr.sr_reason_sk
WHERE cc.cc_name = 'East Call Center'
  AND p.p_discount_active = 'Y'
  AND wp.wp_url LIKE '%foo.com%'
  AND i.inv_quantity_on_hand > 0
GROUP BY
    s.s_state,
    p.p_promo_name,
    r.r_reason_desc
HAVING SUM(ss_unnested.ss_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 100
