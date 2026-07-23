WITH item_promo AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        i.i_rec_start_date,
        p.p_promo_name,
        p.p_discount_active,
        p.p_promo_sk
    FROM tpcds.item i
    JOIN tpcds.promotion p
        ON i.i_item_sk = p.p_item_sk
    WHERE i.i_current_price > 150.00
      AND p.p_discount_active = 'Y'
)
SELECT
    s.s_state,
    s.s_city,
    ip.i_category,
    ip.p_promo_name,
    CASE WHEN ip.i_current_price > 200 THEN 'High' ELSE 'Low' END AS price_tier,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(ws.ws_net_paid_inc_ship) AS total_web_sales,
    SUM(wr.wr_net_loss) AS total_web_returns_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
    (SELECT COUNT(*) FROM tpcds.web_sales) AS total_web_sales_all,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    MAX(ss.ss_ext_sales_price) AS max_store_sales_price
FROM item_promo ip
JOIN tpcds.store_sales ss
    ON ip.i_item_sk = ss.ss_item_sk
   AND ss.ss_promo_sk = ip.p_promo_sk
JOIN tpcds.store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ip.i_item_sk
   AND sr.sr_customer_sk = c.c_customer_sk
   AND sr.sr_store_sk = s.s_store_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_item_sk = ip.i_item_sk
   AND cr.cr_refunded_customer_sk = c.c_customer_sk
   AND cr.cr_returning_customer_sk = c.c_customer_sk
JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.inventory inv
    ON inv.inv_item_sk = ip.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.web_sales ws
    ON ws.ws_item_sk = ip.i_item_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
   AND ws.ws_promo_sk = ip.p_promo_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_ship_customer_sk = c.c_customer_sk
JOIN tpcds.web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ip.i_item_sk
   AND wr.wr_refunded_customer_sk = c.c_customer_sk
   AND wr.wr_returning_customer_sk = c.c_customer_sk
WHERE s.s_floor_space > 7000000
  AND ip.i_rec_start_date >= DATE '2002-01-01'
  AND w.w_gmt_offset = -5.00
  AND EXISTS (
        SELECT 1
        FROM tpcds.call_center cc2
        WHERE cc2.cc_state = s.s_state
          AND cc2.cc_tax_percentage > 0
    )
GROUP BY
    s.s_state,
    s.s_city,
    ip.i_category,
    ip.p_promo_name,
    CASE WHEN ip.i_current_price > 200 THEN 'High' ELSE 'Low' END
HAVING SUM(ss.ss_net_paid_inc_tax) > 1000
ORDER BY total_store_sales DESC
LIMIT 100
