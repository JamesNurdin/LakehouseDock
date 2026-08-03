WITH ss_sr AS (
    SELECT
        ss.*, 
        sr.sr_returned_date_sk,
        sr.sr_fee,
        sr.sr_reason_sk,
        sr.sr_customer_sk,
        sr.sr_hdemo_sk,
        sr.sr_item_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
),
cs_join AS (
    SELECT
        cs.*, 
        cc.cc_name,
        w.w_warehouse_name
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
)
SELECT
    d_sales.d_year,
    c.c_customer_id,
    p.p_promo_name,
    SUM(ss_sr.ss_net_profit) AS total_store_profit,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN cs.cs_net_paid ELSE 0 END) AS promo_net_paid,
    COUNT(DISTINCT ss_sr.ss_ticket_number) AS store_ticket_cnt,
    MAX(ss_sr.sr_fee) AS max_store_return_fee,
    AVG(ws.ws_net_paid) AS avg_web_net_paid,
    MAX(item_qty.total_qty) AS max_catalog_item_qty,
    COUNT(DISTINCT r.r_reason_id) AS distinct_return_reasons
FROM ss_sr
JOIN date_dim d_sales
    ON ss_sr.ss_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_return
    ON ss_sr.sr_returned_date_sk = d_return.d_date_sk
JOIN customer c
    ON ss_sr.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON ss_sr.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
    ON ss_sr.ss_promo_sk = p.p_promo_sk
JOIN cs_join cs
    ON cs.cs_item_sk = ss_sr.ss_item_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN reason r
    ON (ss_sr.sr_reason_sk = r.r_reason_sk OR wr.wr_reason_sk = r.r_reason_sk)
CROSS JOIN LATERAL (
    SELECT SUM(cs2.cs_quantity) AS total_qty
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = cs.cs_item_sk
) AS item_qty(total_qty)
WHERE d_sales.d_year = 2002
  AND ws.ws_quantity > 5
  AND wp.wp_max_ad_count < 3
  AND ss_sr.sr_fee > 50
  AND EXISTS (
        SELECT 1 FROM warehouse w2
        WHERE w2.w_warehouse_sk = cs.cs_warehouse_sk
          AND w2.w_city = 'Seattle'
    )
GROUP BY d_sales.d_year, c.c_customer_id, p.p_promo_name
ORDER BY total_store_profit DESC
LIMIT 100
