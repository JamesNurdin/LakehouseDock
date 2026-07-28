WITH max_inventory AS (
        SELECT inv_warehouse_sk,
               MAX(inv_quantity_on_hand) AS max_qty_on_hand
        FROM inventory
        GROUP BY inv_warehouse_sk
    )
SELECT
    s.s_store_name,
    w.w_warehouse_name,
    p.p_promo_name,
    sm.sm_type,
    t.t_hour,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amount,
    (SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) - SUM(COALESCE(wr.wr_net_loss, 0))) AS adjusted_net_profit,
    max_inv.max_qty_on_hand,
    (SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk) AS store_return_count
FROM store_sales ss
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_sold_time_sk = t.t_time_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN max_inventory max_inv
    ON max_inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE c.c_birth_year = 1985
  AND ca.ca_state = 'CA'
  AND sm.sm_type = 'OVERNIGHT'
  AND inv.inv_date_sk = 2451053
  AND p.p_discount_active = 'Y'
GROUP BY s.s_store_name,
         w.w_warehouse_name,
         p.p_promo_name,
         sm.sm_type,
         t.t_hour,
         max_inv.max_qty_on_hand,
         w.w_warehouse_sk,
         s.s_store_sk
HAVING SUM(ss.ss_ext_sales_price) > 100000
ORDER BY total_store_sales DESC
LIMIT 100
