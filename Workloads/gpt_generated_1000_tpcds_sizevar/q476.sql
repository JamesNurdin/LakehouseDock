WITH
  -- First branch: focus on net profit flag, sampling 10% of items
  branch_one AS (
    SELECT
      i.i_class_id                                 AS class_id,
      d.d_year,
      CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS category_flag,
      COUNT(DISTINCT ws.ws_order_number)          AS order_cnt,
      SUM(ws.ws_ext_sales_price)                  AS sales_amt,
      SUM(COALESCE(wr.wr_return_quantity, 0))     AS return_metric,
      COUNT(DISTINCT w.w_warehouse_id)            AS warehouse_cnt,
      COUNT(DISTINCT t.word)                      AS distinct_desc_words
    FROM
      web_sales ws
      RIGHT OUTER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
      JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
      -- Sampled items (10% Bernoulli)
      JOIN (SELECT * FROM item TABLESAMPLE BERNOULLI (10)) i ON ws.ws_item_sk = i.i_item_sk
      LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
      LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
      LEFT JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
      LEFT JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
      LEFT JOIN call_center cc ON d.d_date_sk = cc.cc_closed_date_sk
      LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                               AND ws.ws_item_sk = wr.wr_item_sk
      LEFT JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word) ON true
    WHERE
      d.d_current_year = 'Y'
    GROUP BY
      i.i_class_id,
      d.d_year,
      CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END
  ),

  -- Second branch: focus on promotion activity, sampling 5% of items
  branch_two AS (
    SELECT
      i.i_class_id                                 AS class_id,
      d.d_year,
      CASE WHEN p.p_discount_active = 'Y' THEN 'Promo' ELSE 'NoPromo' END AS category_flag,
      COUNT(DISTINCT ws.ws_order_number)          AS order_cnt,
      SUM(ws.ws_ext_sales_price)                  AS sales_amt,
      SUM(COALESCE(wr.wr_return_amt_inc_tax, 0))  AS return_metric,
      COUNT(DISTINCT w.w_warehouse_name)          AS warehouse_cnt,
      COUNT(DISTINCT t.word)                      AS distinct_desc_words
    FROM
      web_sales ws
      RIGHT OUTER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
      JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
      -- Sampled items (5% Bernoulli)
      JOIN (SELECT * FROM item TABLESAMPLE BERNOULLI (5)) i ON ws.ws_item_sk = i.i_item_sk
      LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
      LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
      LEFT JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
      LEFT JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
      LEFT JOIN call_center cc ON d.d_date_sk = cc.cc_open_date_sk
      LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                               AND ws.ws_item_sk = wr.wr_item_sk
      LEFT JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word) ON true
    WHERE
      d.d_current_month = 'Y'
    GROUP BY
      i.i_class_id,
      d.d_year,
      CASE WHEN p.p_discount_active = 'Y' THEN 'Promo' ELSE 'NoPromo' END
  ),

  -- Union the two branches (distinct rows)
  union_sales AS (
    SELECT * FROM branch_one
    UNION DISTINCT
    SELECT * FROM branch_two
  )

SELECT
  class_id,
  d_year,
  category_flag,
  SUM(order_cnt)       AS total_orders,
  SUM(sales_amt)       AS total_sales,
  SUM(return_metric)   AS total_returns,
  SUM(warehouse_cnt)   AS total_warehouses,
  SUM(distinct_desc_words) AS total_distinct_words
FROM
  union_sales
GROUP BY
  class_id,
  d_year,
  category_flag
ORDER BY
  total_sales DESC
LIMIT 100
