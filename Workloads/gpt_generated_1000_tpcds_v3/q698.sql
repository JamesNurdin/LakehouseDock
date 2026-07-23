WITH cs_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_item_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND cs.cs_quantity > 5
)
SELECT
    cs_base.cs_order_number,
    d_sold.d_date AS sold_date,
    cs_base.cs_quantity,
    cs_base.cs_net_paid,
    cs_base.cs_net_profit,
    CASE WHEN cs_base.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    w.w_warehouse_name,
    w.w_state,
    ws.ws_quantity,
    ws.ws_net_paid,
    (SELECT SUM(ws2.ws_net_paid)
     FROM web_sales ws2
     WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk) AS total_ws_net_paid,
    r.r_reason_desc,
    inv.inv_quantity_on_hand,
    we.web_name AS web_site_name,
    s.s_store_name,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY cs_base.cs_net_paid DESC) AS warehouse_sales_rank
FROM cs_base
JOIN date_dim d_sold ON cs_base.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs_base.cs_ship_date_sk = d_ship.d_date_sk
JOIN call_center cc ON cs_base.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs_base.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs_base.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs_base.cs_promo_sk = p.p_promo_sk
JOIN customer_address ca_bill ON cs_base.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs_base.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs_base.cs_order_number
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim d_cr_returned ON cr.cr_returned_date_sk = d_cr_returned.d_date_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND w.w_state = 'CA'
  AND r.r_reason_desc LIKE '%price%'
  AND ws.ws_quantity > 10
  AND EXISTS (
      SELECT 1
      FROM catalog_returns cr2
      WHERE cr2.cr_order_number = cs_base.cs_order_number
        AND cr2.cr_return_quantity > 0
  )
ORDER BY warehouse_sales_rank, cs_base.cs_order_number
LIMIT 100
