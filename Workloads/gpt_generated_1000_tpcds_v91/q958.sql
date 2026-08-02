WITH recent_store_sales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2022-01-01'
      AND d.d_date < DATE '2023-01-01'
)
SELECT
    cp.cp_catalog_page_id,
    i.i_item_id,
    d_sales.d_date,
    t_sales.t_hour,
    cd.cd_gender,
    hd.hd_buy_potential,
    SUM(rss.ss_net_paid) AS total_sales_net_paid,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_return_amount,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_catalog_return_amount,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_web_return_amount,
    MAX(inv.inv_quantity_on_hand) AS latest_inventory_quantity
FROM recent_store_sales rss
JOIN item i
  ON rss.ss_item_sk = i.i_item_sk
JOIN date_dim d_sales
  ON rss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
  ON rss.ss_sold_time_sk = t_sales.t_time_sk
JOIN customer_demographics cd
  ON rss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON rss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns sr
  ON sr.sr_item_sk = rss.ss_item_sk
 AND sr.sr_ticket_number = rss.ss_ticket_number
LEFT JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN date_dim d_sr
  ON sr.sr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN time_dim t_sr
  ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
 AND cr.cr_returned_date_sk = d_sales.d_date_sk
 AND cr.cr_returned_time_sk = t_sales.t_time_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN date_dim d_cp_start
  ON cp.cp_start_date_sk = d_cp_start.d_date_sk
LEFT JOIN date_dim d_cp_end
  ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_sold_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
LEFT JOIN web_returns wr
  ON wr.wr_item_sk = ws.ws_item_sk
 AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN time_dim t_wr
  ON wr.wr_returned_time_sk = t_wr.t_time_sk
CROSS JOIN LATERAL (
    SELECT inv.inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
      AND inv.inv_date_sk = d_sales.d_date_sk
    ORDER BY inv.inv_quantity_on_hand DESC
    LIMIT 1
) inv
GROUP BY
    cp.cp_catalog_page_id,
    i.i_item_id,
    d_sales.d_date,
    t_sales.t_hour,
    cd.cd_gender,
    hd.hd_buy_potential
ORDER BY total_sales_net_paid DESC
LIMIT 100
