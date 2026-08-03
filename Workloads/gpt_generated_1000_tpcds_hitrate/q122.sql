WITH
  sales_agg AS (
    SELECT
      cs_sold_time_sk,
      SUM(cs_net_paid) AS total_sales,
      COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_quantity >= 2
      AND cs_net_profit > 0
      AND cs_sold_date_sk BETWEEN 2450800 AND 2450900
      AND cs_ship_mode_sk IS NOT NULL
    GROUP BY cs_sold_time_sk
  ),
  returns_agg AS (
    SELECT
      wr_returned_time_sk,
      wr_web_page_sk,
      wr_reason_sk,
      SUM(wr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_return_amt > 0
      AND wr_returned_date_sk BETWEEN 2450800 AND 2450900
      AND wr_fee IS NOT NULL
      AND wr_net_loss > 0
    GROUP BY wr_returned_time_sk, wr_web_page_sk, wr_reason_sk
  ),
  full_returns_pages AS (
    SELECT
      ra.wr_returned_time_sk,
      ra.wr_web_page_sk,
      ra.wr_reason_sk,
      ra.total_return_amt,
      ra.return_cnt,
      wp.wp_type,
      wp.wp_max_ad_count,
      r.r_reason_desc
    FROM returns_agg ra
    FULL OUTER JOIN web_page wp
      ON ra.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r
      ON ra.wr_reason_sk = r.r_reason_sk
  ),
  order_intersect AS (
    SELECT cs_order_number AS order_number
    FROM catalog_sales
    WHERE cs_quantity > 5
      AND cs_net_paid_inc_tax > 100
      AND cs_sold_time_sk IN (
        SELECT t_time_sk FROM time_dim WHERE t_am_pm = 'PM'
      )
    INTERSECT
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_quantity > 1
      AND wr_return_amt_inc_tax > 50
      AND wr_returned_time_sk IN (
        SELECT t_time_sk FROM time_dim WHERE t_meal_time = 'dinner'
      )
  ),
  joined_data AS (
    SELECT
      s.cs_sold_time_sk,
      s.total_sales,
      s.sales_cnt,
      frp.wr_returned_time_sk,
      frp.total_return_amt,
      frp.return_cnt,
      frp.wp_type,
      frp.wp_max_ad_count,
      frp.r_reason_desc,
      t.t_hour,
      t.t_am_pm,
      t.t_sub_shift,
      ROW_NUMBER() OVER (PARTITION BY s.cs_sold_time_sk ORDER BY s.total_sales DESC) AS sales_rank,
      DENSE_RANK() OVER (ORDER BY frp.total_return_amt DESC) AS return_dense_rank
    FROM sales_agg s
    LEFT JOIN full_returns_pages frp
      ON s.cs_sold_time_sk = frp.wr_returned_time_sk
    JOIN time_dim t
      ON s.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_second IN (0, 2, 3, 8, 14)
      AND t.t_shift = 'morning'
      AND (frp.wp_type = 'article' OR frp.r_reason_desc LIKE '%damaged%')
  )
SELECT
  cs_sold_time_sk,
  total_sales,
  sales_cnt,
  wr_returned_time_sk,
  total_return_amt,
  return_cnt,
  wp_type,
  wp_max_ad_count,
  r_reason_desc,
  t_hour,
  t_am_pm,
  t_sub_shift,
  sales_rank,
  return_dense_rank
FROM joined_data
WHERE cs_sold_time_sk IN (SELECT order_number FROM order_intersect)
ORDER BY sales_rank
LIMIT 100
