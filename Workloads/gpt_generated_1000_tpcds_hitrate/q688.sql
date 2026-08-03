WITH joined_data AS (
  SELECT
    w.w_warehouse_name,
    i.i_brand,
    cd.cd_gender,
    hd.hd_buy_potential,
    td.t_hour,
    ws.ws_sold_date_sk,
    ws.ws_net_paid,
    sr.sr_return_amt,
    cr.cr_return_amount,
    c.c_customer_id,
    p.p_discount_active
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  -- additional dimension tables
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_time_sk = td.t_time_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_returned_time_sk = td.t_time_sk
  LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE td.t_hour BETWEEN 8 AND 20
    AND w.w_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND p.p_discount_active = 'Y'
    AND EXISTS (
      SELECT 1 FROM catalog_returns cr2
      WHERE cr2.cr_item_sk = i.i_item_sk
        AND cr2.cr_returned_time_sk = td.t_time_sk
    )
),
aggregated AS (
  SELECT
    w_warehouse_name,
    i_brand,
    cd_gender,
    hd_buy_potential,
    t_hour,
    (ws_net_paid - COALESCE(sr_return_amt, 0) - COALESCE(cr_return_amount, 0)) AS total_amount,
    c_customer_id
  FROM joined_data
)
SELECT
  w_warehouse_name,
  i_brand,
  cd_gender,
  hd_buy_potential,
  t_hour,
  SUM(total_amount) AS total_amount,
  COUNT(DISTINCT c_customer_id) AS distinct_customers
FROM aggregated
GROUP BY CUBE (w_warehouse_name, i_brand, cd_gender, hd_buy_potential, t_hour)
HAVING SUM(total_amount) > (
  SELECT AVG(inner_total)
  FROM (
    SELECT SUM(ws_net_paid) AS inner_total
    FROM web_sales ws2
    GROUP BY ws2.ws_sold_date_sk
  ) avg_tbl
)
ORDER BY total_amount DESC
LIMIT 100
