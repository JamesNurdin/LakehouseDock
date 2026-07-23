SELECT
    s.s_state AS store_state,
    i.i_category AS item_category,
    t.t_hour AS hour_of_day,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_transactions,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(i.i_current_price) AS min_item_price,
    MAX(i.i_current_price) AS max_item_price
FROM store_sales ss
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_time_sk = t.t_time_sk
   AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cr.cr_warehouse_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_time_sk = t.t_time_sk
   AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE s.s_state = 'CA'
  AND w.w_state = 'TX'
  AND i.i_class_id = 5
  AND i.i_color = 'yellow'
  AND cd.cd_gender = 'M'
  AND ib.ib_upper_bound <= 100000
  AND t.t_hour BETWEEN 9 AND 17
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = i.i_item_sk
          AND wr.wr_order_number = ws.ws_order_number
          AND wr.wr_return_quantity > 0
      )
GROUP BY s.s_state, i.i_category, t.t_hour
HAVING SUM(ss.ss_net_paid) > 10000
   AND COUNT(DISTINCT ss.ss_ticket_number) >= 10
ORDER BY total_store_sales DESC
LIMIT 100
