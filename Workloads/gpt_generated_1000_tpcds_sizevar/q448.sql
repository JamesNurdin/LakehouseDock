WITH sales_cte AS (
   SELECT
      ss.ss_sold_date_sk,
      ss.ss_customer_sk               AS customer_sk,
      c.c_first_name,
      c.c_last_name,
      i.i_item_id,
      i.i_class_id,
      i.i_manager_id,
      hd.hd_income_band_sk            AS ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      ss.ss_quantity,
      ss.ss_ext_sales_price,
      ARRAY[ss.ss_quantity, ss.ss_ext_sales_price] AS sales_array
   FROM store_sales ss
   LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   RIGHT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE i.i_class_id = 12
     AND ib.ib_upper_bound >= 80000
     AND ss.ss_ext_sales_price > 20
),
returns_cte AS (
   SELECT
      wr.wr_returned_date_sk,
      wr.wr_refunded_customer_sk      AS customer_sk,
      c.c_first_name,
      c.c_last_name,
      i.i_item_id,
      i.i_class_id,
      i.i_manager_id,
      hd.hd_income_band_sk            AS ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      ARRAY[wr.wr_return_quantity, wr.wr_return_amt] AS return_array,
      wp.wp_web_page_id
   FROM web_returns wr
   LEFT JOIN item i ON wr.wr_item_sk = i.i_item_sk
   LEFT JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
   LEFT JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE wr.wr_fee > 30
     AND i.i_manager_id = 26
     AND ib.ib_lower_bound <= 100000
),
union_all_cte AS (
   SELECT
      customer_sk,
      c_first_name,
      c_last_name,
      i_item_id,
      i_class_id,
      i_manager_id,
      ib_income_band_sk,
      ib_lower_bound,
      ib_upper_bound,
      val AS metric,
      CASE WHEN src = 'sales' THEN 'quantity' ELSE 'return_quantity' END AS metric_type
   FROM (
      SELECT
         customer_sk,
         c_first_name,
         c_last_name,
         i_item_id,
         i_class_id,
         i_manager_id,
         ib_income_band_sk,
         ib_lower_bound,
         ib_upper_bound,
         sales_array AS arr,
         'sales' AS src
      FROM sales_cte
      UNION DISTINCT
      SELECT
         customer_sk,
         c_first_name,
         c_last_name,
         i_item_id,
         i_class_id,
         i_manager_id,
         ib_income_band_sk,
         ib_lower_bound,
         ib_upper_bound,
         return_array AS arr,
         'returns' AS src
      FROM returns_cte
   ) u
   CROSS JOIN UNNEST(u.arr) AS t(val)
),
final AS (
   SELECT
      customer_sk,
      c_first_name,
      c_last_name,
      i_class_id,
      i_manager_id,
      ib_income_band_sk,
      SUM(CASE WHEN metric_type = 'quantity' THEN metric ELSE 0 END)        AS total_quantity,
      SUM(CASE WHEN metric_type = 'return_quantity' THEN metric ELSE 0 END) AS total_return_quantity,
      SUM(metric)                                                            AS total_metric_sum,
      ROW_NUMBER() OVER (PARTITION BY i_class_id ORDER BY SUM(metric) DESC) AS rn_class,
      RANK()       OVER (ORDER BY SUM(metric) DESC)                         AS overall_rank
   FROM union_all_cte
   GROUP BY
      customer_sk,
      c_first_name,
      c_last_name,
      i_class_id,
      i_manager_id,
      ib_income_band_sk,
      metric_type
)
SELECT
   customer_sk,
   c_first_name,
   c_last_name,
   i_class_id,
   i_manager_id,
   ib_income_band_sk,
   total_quantity,
   total_return_quantity,
   total_metric_sum,
   rn_class,
   overall_rank
FROM final
WHERE rn_class <= 5
ORDER BY overall_rank, total_metric_sum DESC
LIMIT 100
