WITH recent_promos AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_start_date_sk >= 2450500
      AND p_end_date_sk <= 2450600
)
SELECT
    cc.cc_name,
    cp.cp_catalog_number,
    i.i_category,
    td.t_shift,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    AVG(i.i_current_price) AS avg_item_price,
    MAX(p.p_cost) AS max_promo_cost,
    SUM(inv_stock.stock_qty) AS total_inventory_stock
FROM catalog_sales cs
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN recent_promos rp
    ON p.p_promo_sk = rp.p_promo_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN LATERAL (
    SELECT SUM(inv.inv_quantity_on_hand) AS stock_qty
    FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
      AND inv.inv_warehouse_sk = w.w_warehouse_sk
) AS inv_stock ON TRUE
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
   AND ws.ws_sold_time_sk = td.t_time_sk
WHERE td.t_shift = 'second'
  AND td.t_minute <= 15
  AND p.p_channel_catalog = 'N'
  AND p.p_response_target = 1
  AND c.c_email_address LIKE '%@fqKC83UU0f.org'
GROUP BY
    cc.cc_name,
    cp.cp_catalog_number,
    i.i_category,
    td.t_shift
ORDER BY total_catalog_net_paid DESC
LIMIT 100
