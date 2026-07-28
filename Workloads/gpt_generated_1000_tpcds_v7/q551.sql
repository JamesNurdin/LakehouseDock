SELECT
        w.w_warehouse_name || ', ' || w.w_city AS warehouse_location,
        regexp_extract(wsit.web_name, '^([A-Za-z]+)', 1) AS site_prefix,
        COUNT(*) AS returns_cnt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(inv.inv_quantity_on_hand) AS total_stock_on_hand
FROM web_returns wr
JOIN web_sales ws
  ON wr.wr_item_sk = ws.ws_item_sk
  AND wr.wr_order_number = ws.ws_order_number
JOIN web_site wsit
  ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN time_dim td
  ON wr.wr_returned_time_sk = td.t_time_sk
JOIN inventory inv
  ON w.w_warehouse_sk = inv.inv_warehouse_sk
WHERE regexp_like(wsit.web_name, '^Online.*')
  AND td.t_am_pm = 'PM'
  AND w.w_warehouse_name LIKE '%WAREHOUSE%'
GROUP BY
        w.w_warehouse_name,
        w.w_city,
        regexp_extract(wsit.web_name, '^([A-Za-z]+)', 1)
ORDER BY total_net_loss DESC
LIMIT 20
