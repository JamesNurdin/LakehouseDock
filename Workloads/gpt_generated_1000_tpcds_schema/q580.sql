WITH
  sampled_sales AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
  ),
  sampled_returns AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
  ),
  reason_small AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%not%'
  ),
  computed_set AS (
    SELECT seq
    FROM (VALUES 1, 2, 3) AS t(seq)
  ),
  sales_data AS (
    SELECT
      cs.cs_order_number AS order_id,
      cs.cs_ext_sales_price AS sales_amount,
      i.i_category,
      i.i_brand,
      t.t_hour,
      c.c_customer_sk,
      CAST(NULL AS varchar) AS store_state,
      CAST(NULL AS varchar) AS reason_desc,
      CAST(NULL AS varchar) AS wp_type
    FROM sampled_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_sales_price > 100
      AND t.t_hour BETWEEN 8 AND 20
      AND i.i_current_price > 20
      AND c.c_birth_year BETWEEN 1960 AND 1990
      AND i.i_category IS NOT NULL
  ),
  returns_data AS (
    SELECT
      sr.sr_ticket_number AS order_id,
      sr.sr_return_amt AS sales_amount,
      i.i_category,
      i.i_brand,
      t.t_hour,
      c.c_customer_sk,
      s.s_state AS store_state,
      r.r_reason_desc,
      CAST(NULL AS varchar) AS wp_type
    FROM sampled_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt > 0
      AND s.s_state = 'CA'
      AND r.r_reason_desc LIKE '%not%'
      AND t.t_hour >= 9
      AND i.i_current_price > 30
  ),
  web_data AS (
    SELECT
      wr.wr_order_number AS order_id,
      wr.wr_return_amt AS sales_amount,
      i.i_category,
      i.i_brand,
      t.t_hour,
      c.c_customer_sk,
      CAST(NULL AS varchar) AS store_state,
      r.r_reason_desc,
      wp.wp_type
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_return_amt > 0
      AND t.t_hour < 12
      AND i.i_current_price BETWEEN 10 AND 100
      AND r.r_reason_sk IN (10, 11, 13)
      AND wp.wp_type = 'content'
  ),
  union_all_data AS (
    SELECT * FROM sales_data
    UNION
    SELECT * FROM returns_data
    UNION
    SELECT * FROM web_data
  ),
  ranked_data AS (
    SELECT
      order_id,
      sales_amount,
      i_category,
      i_brand,
      t_hour,
      c_customer_sk,
      store_state,
      reason_desc,
      wp_type,
      ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY sales_amount DESC) AS rn_category,
      RANK() OVER (ORDER BY sales_amount DESC) AS overall_rank
    FROM union_all_data
    WHERE sales_amount IS NOT NULL
  ),
  final_cubed AS (
    SELECT
      i_category,
      store_state,
      t_hour,
      SUM(sales_amount) AS total_sales,
      COUNT(DISTINCT c_customer_sk) AS customer_cnt,
      MIN(overall_rank) AS best_rank
    FROM ranked_data
    CROSS JOIN reason_small
    CROSS JOIN computed_set
    GROUP BY CUBE (i_category, store_state, t_hour)
  )
SELECT *
FROM final_cubed
WHERE total_sales > 0
EXCEPT
SELECT *
FROM final_cubed
WHERE i_category IS NULL
ORDER BY total_sales DESC
LIMIT 100
