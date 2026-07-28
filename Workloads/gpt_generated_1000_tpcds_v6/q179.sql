WITH inventory_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk
)
SELECT
    s.s_store_name,
    i.i_item_id,
    i.i_brand,
    hd.hd_vehicle_count,
    ib.ib_upper_bound,
    p.p_promo_name,
    td.t_hour,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(wr.wr_return_amt) AS total_web_returns,
    inventory_agg.total_on_hand,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN time_dim td
  ON ss.ss_sold_time_sk = td.t_time_sk
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws
  ON ws.ws_item_sk = ss.ss_item_sk
 AND ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN inventory_agg
  ON inventory_agg.inv_item_sk = i.i_item_sk
WHERE
    s.s_market_desc LIKE '%Architects%'
  AND s.s_number_employees >= 220
  AND hd.hd_vehicle_count >= 1
  AND ib.ib_upper_bound <= 110000
  AND p.p_discount_active = 'Y'
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY
    s.s_store_name,
    i.i_item_id,
    i.i_brand,
    hd.hd_vehicle_count,
    ib.ib_upper_bound,
    p.p_promo_name,
    td.t_hour,
    inventory_agg.total_on_hand
ORDER BY total_store_sales DESC
LIMIT 100
