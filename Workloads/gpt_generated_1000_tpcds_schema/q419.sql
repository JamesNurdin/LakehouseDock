WITH
  -- Aggregate store sales per address and date
  store_agg AS (
    SELECT
      ss_addr_sk,
      ss_sold_date_sk,
      SUM(ss_ext_sales_price) AS store_total_sales,
      SUM(ss_quantity) AS store_total_qty
    FROM store_sales
    WHERE ss_addr_sk IN (
            SELECT ca_address_sk
            FROM customer_address
            WHERE ca_country = 'United States'
          )
      AND ss_ext_sales_price > 1000
    GROUP BY ss_addr_sk, ss_sold_date_sk
  ),

  -- Order numbers that appear both in profitable web sales and lossful returns
  order_intersect AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_net_profit > 1000
    INTERSECT
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_net_loss < -500
  ),

  -- Split manager name into an array for UNNEST example
  manager_array AS (
    SELECT
      ws.ws_order_number,
      ws.ws_web_site_sk,
      split(web_site.web_manager, ' ') AS manager_parts
    FROM web_sales ws
    JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    WHERE web_site.web_manager LIKE '%Jones%'
  )
SELECT
  d.d_date,
  ca.ca_city,
  ca.ca_state,
  sm.sm_code,
  w.w_warehouse_name,
  ws.ws_order_number,
  ws.ws_net_profit,
  store_agg.store_total_sales,
  ROW_NUMBER() OVER (
    PARTITION BY w.w_city
    ORDER BY store_agg.store_total_sales DESC
  ) AS city_sales_rank,
  manager_part
FROM date_dim d
JOIN store_agg ON d.d_date_sk = store_agg.ss_sold_date_sk
JOIN customer_address ca ON ca.ca_address_sk = store_agg.ss_addr_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN manager_array ma ON ma.ws_order_number = ws.ws_order_number
CROSS JOIN UNNEST(ma.manager_parts) AS u(manager_part)
WHERE d.d_year = 1998
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND ca.ca_state = 'CA'
  AND sm.sm_code = 'AIR'
  AND w.w_city = 'Oak Grove'
  AND EXISTS (SELECT 1 FROM order_intersect oi WHERE oi.ws_order_number = ws.ws_order_number)
ORDER BY store_agg.store_total_sales DESC
LIMIT 100
