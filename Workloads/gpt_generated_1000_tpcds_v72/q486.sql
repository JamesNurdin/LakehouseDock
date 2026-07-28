WITH joined AS (
  SELECT
    s.s_store_name,
    wsite.web_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    i.i_brand,
    r.r_reason_desc,
    ss.ss_ticket_number,
    ws.ws_order_number,
    ss.ss_net_profit AS store_profit,
    ws.ws_net_profit AS web_profit,
    i.i_current_price,
    inv.inv_quantity_on_hand
  FROM store_sales ss
  JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN time_dim t_sales
    ON ss.ss_sold_time_sk = t_sales.t_time_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
  JOIN date_dim d_return_store
    ON sr.sr_returned_date_sk = d_return_store.d_date_sk
  JOIN time_dim t_return_store
    ON sr.sr_return_time_sk = t_return_store.t_time_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
   AND inv.inv_date_sk = d_sales.d_date_sk
  JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws
    ON ss.ss_ticket_number = ws.ws_order_number
   AND ss.ss_item_sk = ws.ws_item_sk
  JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
  JOIN time_dim t_ws_sold
    ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
  JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
  JOIN date_dim d_return_web
    ON wr.wr_returned_date_sk = d_return_web.d_date_sk
  JOIN time_dim t_return_web
    ON wr.wr_returned_time_sk = t_return_web.t_time_sk
  JOIN reason r2
    ON wr.wr_reason_sk = r2.r_reason_sk
  WHERE d_sales.d_year = 2001
    AND d_sales.d_month_seq = 12
    AND t_sales.t_meal_time = 'dinner'
    AND r.r_reason_desc = 'Package was damaged'
    AND i.i_brand = 'Brand#12'
),
aggregated AS (
  SELECT
    s_store_name,
    web_name,
    d_year,
    d_month_seq,
    i_brand,
    COUNT(DISTINCT ss_ticket_number) AS distinct_store_sales,
    COUNT(DISTINCT ws_order_number) AS distinct_web_orders,
    SUM(store_profit) AS total_store_profit,
    SUM(web_profit) AS total_web_profit,
    AVG(i_current_price) AS avg_item_price,
    MIN(inv_quantity_on_hand) AS min_inventory,
    MAX(inv_quantity_on_hand) AS max_inventory
  FROM joined
  GROUP BY s_store_name, web_name, d_year, d_month_seq, i_brand
)
SELECT
  s_store_name,
  web_name,
  d_year,
  d_month_seq,
  i_brand,
  distinct_store_sales,
  distinct_web_orders,
  total_store_profit,
  total_web_profit,
  avg_item_price,
  min_inventory,
  max_inventory,
  RANK() OVER (ORDER BY total_store_profit + total_web_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_store_profit DESC, total_web_profit DESC
LIMIT 100
