WITH
  catalog AS (
    SELECT
      cs.cs_order_number,
      d.d_year,
      cc.cc_name,
      cp.cp_type,
      cs.cs_net_profit AS cat_net_profit,
      inv.inv_quantity_on_hand,
      cust.c_birth_year,
      cust.c_birth_country,
      cd.cd_gender,
      w.w_state,
      cc.cc_country,
      t.t_meal_time
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND t.t_meal_time = 'dinner'
      AND cc.cc_country = 'United States'
      AND w.w_state = 'CA'
      AND cust.c_birth_year BETWEEN 1950 AND 1970
      AND inv.inv_quantity_on_hand > 100
  ),
  cat_ret AS (
    SELECT
      cr.cr_order_number,
      d.d_year,
      cc.cc_name,
      cr.cr_net_loss AS cat_return_loss,
      t.t_meal_time
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND t.t_meal_time = 'dinner'
  ),
  store AS (
    SELECT
      ss.ss_ticket_number,
      d.d_year,
      ss.ss_net_profit AS store_net_profit,
      t.t_meal_time
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND t.t_meal_time = 'dinner'
  ),
  store_ret AS (
    SELECT
      sr.sr_ticket_number,
      d.d_year,
      sr.sr_net_loss AS store_return_loss,
      t.t_meal_time
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND t.t_meal_time = 'dinner'
  ),
  web_ret AS (
    SELECT
      wr.wr_net_loss AS web_return_loss,
      d.d_year,
      wp.wp_type,
      t.t_meal_time
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND t.t_meal_time = 'dinner'
      AND wp.wp_type = 'content'
  )
SELECT
  cat.cc_name,
  cat.d_year,
  SUM(cat.cat_net_profit)                     AS total_catalog_profit,
  SUM(cr.cat_return_loss)                     AS total_catalog_return_loss,
  SUM(st.store_net_profit)                    AS total_store_profit,
  SUM(sr.store_return_loss)                   AS total_store_return_loss,
  SUM(wr.web_return_loss)                    AS total_web_return_loss,
  COUNT(DISTINCT cat.cp_type)                 AS distinct_catalog_page_types,
  AVG(cat.inv_quantity_on_hand)               AS avg_inventory_qty,
  (SELECT AVG(cs.cs_net_profit)
       FROM catalog_sales cs
       JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
       WHERE d2.d_year = 2001)               AS avg_catalog_profit_all
FROM catalog cat
LEFT JOIN cat_ret cr
       ON cat.cs_order_number = cr.cr_order_number
      AND cat.d_year = cr.d_year
LEFT JOIN store st
       ON cat.d_year = st.d_year
LEFT JOIN store_ret sr
       ON st.ss_ticket_number = sr.sr_ticket_number
      AND st.d_year = sr.d_year
LEFT JOIN web_ret wr
       ON cat.d_year = wr.d_year
GROUP BY
  cat.cc_name,
  cat.d_year
HAVING
  SUM(cat.cat_net_profit) > 10000
ORDER BY
  total_catalog_profit DESC
LIMIT 100
