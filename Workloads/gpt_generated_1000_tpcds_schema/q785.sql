WITH
  -- First branch with a set of filters
  sel1 AS (
    SELECT
      d_sold.d_year,
      i.i_category,
      wh.w_state,
      CASE WHEN hd_bill.hd_buy_potential = '>10000' THEN 'High' ELSE 'Other' END AS buy_pot_category,
      SUM(cr.cr_return_amount)               AS total_catalog_return,
      SUM(wr.wr_return_amt)                  AS total_web_return,
      COUNT(DISTINCT cs.cs_order_number)     AS order_cnt,
      AVG(cs.cs_sales_price)                 AS avg_sales_price,
      (SELECT MAX(d2.d_year) FROM date_dim d2) AS max_year
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    FULL OUTER JOIN date_dim d_full
      ON cs.cs_sold_date_sk = d_full.d_date_sk
    JOIN customer cust
      ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN warehouse wh
      ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN (
          SELECT * FROM item TABLESAMPLE BERNOULLI (10)
        ) i
      ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d_sold.d_year = 2001
      AND t_sold.t_hour = 10
      AND i.i_category = 'Sports'
      AND hd_bill.hd_vehicle_count > 0
      AND wh.w_state = 'CA'
      AND r.r_reason_desc = 'Customer Not Satisfied'
    GROUP BY
      d_sold.d_year,
      i.i_category,
      wh.w_state,
      hd_bill.hd_buy_potential
  ),
  -- Second branch with a different set of filters (same join shape)
  sel2 AS (
    SELECT
      d_sold.d_year,
      i.i_category,
      wh.w_state,
      CASE WHEN hd_bill.hd_buy_potential = '>10000' THEN 'High' ELSE 'Other' END AS buy_pot_category,
      SUM(cr.cr_return_amount)               AS total_catalog_return,
      SUM(wr.wr_return_amt)                  AS total_web_return,
      COUNT(DISTINCT cs.cs_order_number)     AS order_cnt,
      AVG(cs.cs_sales_price)                 AS avg_sales_price,
      (SELECT MAX(d2.d_year) FROM date_dim d2) AS max_year
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    FULL OUTER JOIN date_dim d_full
      ON cs.cs_sold_date_sk = d_full.d_date_sk
    JOIN customer cust
      ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN warehouse wh
      ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    JOIN (
          SELECT * FROM item TABLESAMPLE BERNOULLI (10)
        ) i
      ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d_sold.d_year = 2000
      AND t_sold.t_hour = 14
      AND i.i_category = 'Books'
      AND hd_bill.hd_vehicle_count <= 0
      AND wh.w_state = 'NY'
      AND r.r_reason_desc = 'Damaged Item'
    GROUP BY
      d_sold.d_year,
      i.i_category,
      wh.w_state,
      hd_bill.hd_buy_potential
  )
SELECT
  d_year,
  i_category,
  w_state,
  buy_pot_category,
  SUM(total_catalog_return) AS total_catalog_return,
  SUM(total_web_return)    AS total_web_return,
  SUM(order_cnt)           AS total_orders,
  AVG(avg_sales_price)    AS avg_sales_price,
  MAX(max_year)            AS max_year_observed
FROM (
  SELECT * FROM sel1
  UNION
  SELECT * FROM sel2
) u
GROUP BY
  d_year,
  i_category,
  w_state,
  buy_pot_category
ORDER BY total_catalog_return DESC
LIMIT 100
