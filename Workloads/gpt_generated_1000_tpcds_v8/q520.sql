WITH
  -- Build a map of address attributes to be unnested later
  address_map AS (
    SELECT
      ca_address_sk,
      map(
        ARRAY['state', 'country'],
        ARRAY[ca_state, ca_country]
      ) AS info_map
    FROM customer_address
  ),

  -- Orders that appear in both catalog and web returns
  orders_from_cr AS (
    SELECT cr_order_number AS order_num
    FROM catalog_returns
    WHERE cr_return_quantity > 0
  ),
  orders_from_wr AS (
    SELECT wr_order_number AS order_num
    FROM web_returns
    WHERE wr_return_quantity > 0
  ),
  common_orders AS (
    SELECT order_num FROM orders_from_cr
    INTERSECT
    SELECT order_num FROM orders_from_wr
  ),

  -- Core join of all eleven tables (using only the permitted join keys)
  base AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_quantity AS ss_qty,
      ss.ss_net_paid AS ss_net_paid,
      ss.ss_net_profit AS ss_net_profit,
      cr.cr_return_quantity AS cr_ret_qty,
      cr.cr_net_loss AS cr_net_loss,
      ws.ws_quantity AS ws_qty,
      ws.ws_net_paid AS ws_net_paid,
      ws.ws_net_profit AS ws_net_profit,
      wr.wr_return_quantity AS wr_ret_qty,
      wr.wr_net_loss AS wr_net_loss,
      d.d_year,
      d.d_month_seq,
      t.t_hour,
      i.i_brand,
      i.i_category,
      sm.sm_type,
      w.w_warehouse_name,
      ca.ca_state,
      ca.ca_country,
      wp.wp_max_ad_count,
      ca.ca_address_sk AS addr_sk,
      cr.cr_returning_addr_sk
    FROM store_sales ss
    JOIN date_dim d               ON ss.ss_sold_date_sk   = d.d_date_sk
    JOIN time_dim t               ON ss.ss_sold_time_sk   = t.t_time_sk
    JOIN item i                   ON ss.ss_item_sk        = i.i_item_sk
    JOIN customer_address ca      ON ss.ss_addr_sk        = ca.ca_address_sk
    LEFT JOIN catalog_returns cr  ON cr.cr_item_sk        = i.i_item_sk
                                 AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws       ON ws.ws_item_sk       = i.i_item_sk
                                 AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr     ON wr.wr_item_sk       = i.i_item_sk
                                 AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN warehouse w        ON w.w_warehouse_sk    = COALESCE(cr.cr_warehouse_sk, ws.ws_warehouse_sk)
    LEFT JOIN ship_mode sm       ON sm.sm_ship_mode_sk = COALESCE(cr.cr_ship_mode_sk, ws.ws_ship_mode_sk)
    LEFT JOIN web_page wp        ON wp.wp_web_page_sk   = ws.ws_web_page_sk
    -- LATERAL correlated join to fetch the returning address details
    CROSS JOIN LATERAL (
      SELECT ca2.ca_state AS ret_state, ca2.ca_zip AS ret_zip
      FROM customer_address ca2
      WHERE ca2.ca_address_sk = cr.cr_returning_addr_sk
      LIMIT 1
    ) ca_ret
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_current_price > 100
      AND sm.sm_type IS NOT NULL
      AND w.w_state = 'CA'
      AND ca.ca_country = 'United States'
      AND wp.wp_max_ad_count >= 2
      AND EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_web_page_sk = ws.ws_web_page_sk
          AND wp2.wp_max_ad_count > 1
      )
  )

SELECT
  d_year,
  i_brand,
  i_category,
  SUM(ss_net_paid)   AS total_store_sales,
  SUM(ws_net_paid)   AS total_web_sales,
  SUM(cr_net_loss)   AS total_catalog_returns,
  SUM(wr_net_loss)   AS total_web_returns,
  COUNT(DISTINCT ss_ticket_number) AS distinct_transactions
FROM (
  SELECT b.*, am.info_map
  FROM base b
  JOIN address_map am ON am.ca_address_sk = b.addr_sk
  -- Expand the map so we can filter on a particular attribute
  CROSS JOIN UNNEST(am.info_map) AS t (attr, val)
  WHERE attr = 'state' AND val = 'CA'
) x
WHERE x.ss_ticket_number IN (SELECT order_num FROM common_orders)
GROUP BY GROUPING SETS (
        (d_year, i_brand, i_category),
        (d_year, i_brand),
        (d_year)
      )
HAVING SUM(ss_net_paid) > 1000
ORDER BY total_store_sales DESC
LIMIT 100
