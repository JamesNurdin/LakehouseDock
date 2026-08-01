WITH
  sampled_store_sales AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_store_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_ticket_number,
      d.d_date_sk,
      d.d_year,
      d.d_month_seq,
      t.t_hour,
      i.i_brand,
      i.i_category,
      s.s_state,
      s.s_store_name,
      ca.ca_city,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  ),
  orders_without_returns AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    EXCEPT
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
  ),
  unioned_sales AS (
    SELECT
      s.s_state AS state,
      i.i_brand AS brand,
      d.d_year AS year,
      ss.ss_net_paid AS total_sales,
      ss.ss_quantity AS quantity,
      ss.ss_ticket_number AS order_key,
      ss.ss_net_paid AS min_sales,
      ss.ss_net_paid AS max_sales,
      d.d_date_sk AS date_sk
    FROM sampled_store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND ss.ss_quantity > 5
      AND ss.ss_net_paid > 100
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND ss.ss_ticket_number IN (SELECT order_number FROM orders_without_returns)
    UNION DISTINCT
    SELECT
      cc.cc_state AS state,
      i.i_brand AS brand,
      d.d_year AS year,
      cs.cs_net_paid AS total_sales,
      cs.cs_quantity AS quantity,
      cs.cs_order_number AS order_key,
      cs.cs_net_paid AS min_sales,
      cs.cs_net_paid AS max_sales,
      d.d_date_sk AS date_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND cs.cs_quantity > 5
      AND cs.cs_net_paid > 100
      AND cp.cp_department = 'DEPARTMENT'
      AND cs.cs_order_number IN (SELECT order_number FROM orders_without_returns)
  ),
  aggregated AS (
    SELECT
      state,
      brand,
      year,
      SUM(total_sales) AS sum_sales,
      AVG(quantity) AS avg_quantity,
      COUNT(DISTINCT order_key) AS order_cnt,
      MIN(min_sales) AS min_sales,
      MAX(max_sales) AS max_sales,
      date_sk
    FROM unioned_sales
    GROUP BY GROUPING SETS (
      (state, brand, year, date_sk),
      (state, brand, date_sk),
      (state, date_sk),
      (brand, date_sk),
      (date_sk)
    )
  )
SELECT
  a.state,
  a.brand,
  a.year,
  a.sum_sales,
  a.avg_quantity,
  a.order_cnt,
  a.min_sales,
  a.max_sales,
  LAG(a.sum_sales) OVER (PARTITION BY a.state ORDER BY a.year) AS lag_sum_sales,
  wp.wp_url
FROM aggregated a
LEFT OUTER JOIN web_page wp ON wp.wp_creation_date_sk = a.date_sk
WHERE wp.wp_type = 'HOME'
ORDER BY a.sum_sales DESC
LIMIT 100
