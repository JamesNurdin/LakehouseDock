WITH
  -- Union of order numbers and amounts from catalog and web sales
  union_orders AS (
    SELECT cs.cs_order_number AS order_number,
           cs.cs_net_paid        AS amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cs.cs_quantity > 3
    UNION
    SELECT ws.ws_order_number AS order_number,
           ws.ws_net_paid      AS amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ws.ws_quantity > 3
  ),
  -- Orders that appear both in returns and in store sales
  intersect_orders AS (
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cr.cr_return_quantity > 0
    INTERSECT
    SELECT ss.ss_ticket_number AS order_number
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ss.ss_quantity > 2
  ),
  -- Orders that are in the union but not in the intersect set
  except_orders AS (
    SELECT order_number FROM union_orders
    EXCEPT
    SELECT order_number FROM intersect_orders
  ),
  -- Final aggregation over catalog sales joined to the rest of the dimension tables
  final_agg AS (
    SELECT
      d.d_year,
      cp.cp_department,
      w.w_state,
      sm.sm_carrier,
      cd.cd_gender,
      hd.hd_buy_potential,
      COUNT(DISTINCT eo.order_number)                 AS order_cnt,
      SUM(cs.cs_net_paid)                             AS total_net_paid,
      AVG(cs.cs_net_profit)                           AS avg_net_profit,
      MIN(cs.cs_net_paid)                             AS min_net_paid,
      MAX(cs.cs_net_paid)                             AS max_net_paid
    FROM date_dim d
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
    JOIN except_orders eo ON eo.order_number = cs.cs_order_number
    WHERE d.d_year = 2002
      AND cp.cp_department = 'Electronics'
      AND w.w_gmt_offset = -5.00
      AND sm.sm_carrier = 'UPS'
      AND cd.cd_gender = 'M'
    GROUP BY
      d.d_year,
      cp.cp_department,
      w.w_state,
      sm.sm_carrier,
      cd.cd_gender,
      hd.hd_buy_potential
  )
SELECT
  d_year,
  cp_department,
  w_state,
  sm_carrier,
  cd_gender,
  hd_buy_potential,
  order_cnt,
  total_net_paid,
  avg_net_profit,
  min_net_paid,
  max_net_paid
FROM final_agg
ORDER BY order_cnt DESC
LIMIT 10
