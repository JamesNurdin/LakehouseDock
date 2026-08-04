WITH
  full_cust AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      c.c_birth_year,
      cd.cd_demo_sk,
      cd.cd_gender,
      cd.cd_marital_status
    FROM customer c
    FULL OUTER JOIN customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
  ),
  items_no_store AS (
    SELECT inv_item_sk
    FROM inventory
    EXCEPT
    SELECT ss_item_sk
    FROM store_sales
  ),
  joined AS (
    SELECT
      cs.cs_sold_date_sk,
      td.t_meal_time,
      i.i_category,
      i.i_brand,
      i.i_color,
      fc.c_customer_sk,
      fc.c_first_name,
      fc.c_last_name,
      fc.cd_gender,
      cs.cs_net_paid_inc_ship_tax,
      CASE
        WHEN cs.cs_net_paid_inc_ship_tax > 1000 THEN 'High'
        ELSE 'Low'
      END AS payment_category,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      r.r_reason_desc,
      ss.ss_quantity,
      ws.ws_quantity,
      inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN full_cust fc ON cs.cs_bill_customer_sk = fc.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = cs.cs_item_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = cs.cs_item_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = cs.cs_item_sk
    WHERE td.t_meal_time = 'dinner'
      AND i.i_category = 'Women''s'
      AND fc.c_birth_year BETWEEN 1970 AND 1990
      AND cc.cc_state = 'CA'
      AND fc.cd_gender = 'F'
      AND inv.inv_quantity_on_hand > 500
      AND cs.cs_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'BrandX')
      AND cs.cs_item_sk NOT IN (SELECT inv_item_sk FROM items_no_store)
  )
SELECT
  joined.t_meal_time,
  joined.i_category,
  joined.i_brand,
  SUM(joined.cs_net_paid_inc_ship_tax) AS total_net_paid,
  AVG(joined.cs_net_paid_inc_ship_tax) AS avg_net_paid,
  COUNT(DISTINCT joined.c_customer_sk) AS distinct_customers,
  SUM(CASE WHEN joined.payment_category = 'High' THEN 1 ELSE 0 END) AS high_payment_cnt
FROM joined
GROUP BY
  joined.t_meal_time,
  joined.i_category,
  joined.i_brand
HAVING SUM(joined.cs_net_paid_inc_ship_tax) > 10000
ORDER BY total_net_paid DESC
LIMIT 20
