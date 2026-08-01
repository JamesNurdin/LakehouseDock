WITH
  cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  ws_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  catalog_not_in_web AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT ws_order_number
    FROM web_sales
  ),
  raw_union AS (
    SELECT DISTINCT
      c.c_customer_id,
      i.i_category,
      cs.cs_order_number          AS order_number,
      cs.cs_net_paid              AS net_paid,
      'catalog'                   AS src,
      w.w_warehouse_name          AS warehouse_name,
      td.t_hour                   AS hour_of_day,
      c.c_customer_sk
    FROM cs_sample cs
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td              ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cc.cc_employees > 3000000
      AND cc.cc_state = 'CA'
      AND i.i_current_price > 50
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'

    UNION DISTINCT

    SELECT DISTINCT
      c.c_customer_id,
      i.i_category,
      ws.ws_order_number          AS order_number,
      ws.ws_net_paid              AS net_paid,
      'web'                       AS src,
      w.w_warehouse_name          AS warehouse_name,
      td.t_hour                   AS hour_of_day,
      c.c_customer_sk
    FROM ws_sample ws
    JOIN customer c               ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we              ON ws.ws_web_site_sk = we.web_site_sk
    JOIN item i                   ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p              ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm             ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w              ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td              ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE we.web_state = 'CA'
      AND i.i_current_price > 60
      AND wp.wp_type = 'product'
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
      AND we.web_company_id = 1
  ),
  filtered_union AS (
    SELECT *
    FROM raw_union ru
    WHERE NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_order_number = ru.order_number
          )
      AND NOT EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = ru.order_number
          )
      AND ru.order_number IN (SELECT cs_order_number FROM catalog_not_in_web)
  ),
  aggregated AS (
    SELECT
      c_customer_id,
      i_category,
      src,
      SUM(net_paid)                              AS total_net_paid,
      COUNT(DISTINCT order_number)               AS distinct_orders,
      MAX(net_paid)                              AS max_order_value,
      (
        SELECT COUNT(*)
        FROM catalog_sales cs3
        WHERE cs3.cs_bill_customer_sk = (
                SELECT c2.c_customer_sk
                FROM customer c2
                WHERE c2.c_customer_id = c_customer_id
              )
      )                                          AS total_catalog_orders
    FROM filtered_union
    GROUP BY ROLLUP (c_customer_id, i_category, src)
  )
SELECT *
FROM (
  SELECT *
  FROM aggregated
  WHERE total_net_paid > 0
  EXCEPT
  SELECT *
  FROM aggregated
  WHERE src = 'web' AND i_category = 'Obsolete'
) final_result
ORDER BY total_net_paid DESC
LIMIT 100
