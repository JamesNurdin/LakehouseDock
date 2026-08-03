WITH
  store_data AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_store_sk,
      ss.ss_quantity,
      ss.ss_sales_price,
      ss.ss_net_profit,
      c.c_customer_id,
      i.i_item_id,
      i.i_color,
      d.d_year,
      t.t_hour,
      s.s_store_name,
      hd.hd_buy_potential
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
      AND i.i_current_price > 100
      AND s.s_state = 'CA'
  ),
  web_data AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_returned_time_sk,
      wr.wr_item_sk,
      wr.wr_refunded_customer_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      c.c_customer_id,
      i.i_item_id,
      i.i_color,
      d.d_year,
      t.t_hour,
      hd.hd_buy_potential
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
      AND i.i_current_price > 100
      AND c.c_preferred_cust_flag = 'Y'
  ),
  union_set AS (
    SELECT
      c_customer_id,
      i_item_id,
      d_year,
      SUM(ss_quantity) AS total_qty,
      SUM(ss_sales_price) AS total_sales
    FROM store_data
    GROUP BY c_customer_id, i_item_id, d_year
    UNION
    SELECT
      c_customer_id,
      i_item_id,
      d_year,
      SUM(wr_return_quantity) AS total_qty,
      SUM(wr_return_amt) AS total_sales
    FROM web_data
    GROUP BY c_customer_id, i_item_id, d_year
  ),
  store_return_customers AS (
    SELECT DISTINCT c.c_customer_id
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  ),
  filtered_set AS (
    SELECT *
    FROM union_set
    EXCEPT
    SELECT c_customer_id, i_item_id, d_year, total_qty, total_sales
    FROM union_set
    WHERE c_customer_id IN (SELECT c_customer_id FROM store_return_customers)
  ),
  final AS (
    SELECT
      f.c_customer_id,
      f.i_item_id,
      f.d_year,
      f.total_qty,
      f.total_sales,
      (
        SELECT COALESCE(SUM(sr.sr_return_amt), 0)
        FROM store_returns sr
        JOIN customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
        WHERE c2.c_customer_id = f.c_customer_id
      ) AS customer_return_amount,
      col.col_part
    FROM filtered_set f
    LEFT JOIN LATERAL (
      SELECT col_part
      FROM item i
      CROSS JOIN UNNEST(split(i.i_color, ' ')) AS t(col_part)
      WHERE i.i_item_id = f.i_item_id
    ) AS col ON TRUE
  )
SELECT
  c_customer_id,
  i_item_id,
  d_year,
  SUM(total_qty) AS sum_qty,
  SUM(total_sales) AS sum_sales,
  MAX(customer_return_amount) AS max_return_amount,
  COUNT(DISTINCT col_part) AS distinct_color_parts
FROM final
GROUP BY c_customer_id, i_item_id, d_year
ORDER BY sum_sales DESC
LIMIT 100
