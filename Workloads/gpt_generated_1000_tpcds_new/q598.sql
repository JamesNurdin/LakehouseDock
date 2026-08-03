WITH
  -- Aggregate sales per date, time, store and customer
  sales_agg AS (
    SELECT
      ss_sold_date_sk,
      ss_sold_time_sk,
      ss_store_sk,
      ss_customer_sk,
      SUM(ss_net_paid)        AS total_sales,
      COUNT(*)                AS sales_cnt
    FROM store_sales
    WHERE ss_net_paid > 0
      AND ss_coupon_amt > 100
      AND ss_list_price BETWEEN 30 AND 100
    GROUP BY ss_sold_date_sk, ss_sold_time_sk, ss_store_sk, ss_customer_sk
  ),
  -- Aggregate inventory per date
  inventory_agg AS (
    SELECT
      inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_date_sk
  ),
  -- Filtered web page data
  web_page_data AS (
    SELECT
      wp_web_page_id,
      wp_url,
      wp_char_count,
      wp_link_count,
      wp_creation_date_sk,
      wp_customer_sk,
      wp_type
    FROM web_page
    WHERE wp_type = 'article'
      AND wp_char_count > 1000
      AND wp_link_count BETWEEN 5 AND 50
  ),
  -- Expand a derived array of two page metrics
  unnest_wp AS (
    SELECT
      wp_web_page_id,
      metric_value
    FROM web_page_data wp
    CROSS JOIN UNNEST(ARRAY[wp_char_count, wp_link_count]) AS t(metric_value)
  ),
  -- Stores that have sales (used for EXCEPT later)
  stores_with_sales AS (
    SELECT DISTINCT s.s_store_sk
    FROM store s
    JOIN sales_agg sa ON s.s_store_sk = sa.ss_store_sk
  ),
  -- Stores that never had sales – created with EXCEPT
  stores_without_sales AS (
    SELECT s.s_store_sk
    FROM store s
    EXCEPT
    SELECT sws.s_store_sk FROM stores_with_sales sws
  ),
  -- Detailed sales joined to other dimensions (pre‑aggregation still kept)
  sales_detail AS (
    SELECT
      d.d_date,
      d.d_date_sk,
      s.s_store_name,
      s.s_store_sk,
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      t.t_hour,
      t.t_sub_shift,
      sa.total_sales,
      sa.sales_cnt,
      i.total_qty
    FROM sales_agg sa
    JOIN date_dim d          ON sa.ss_sold_date_sk = d.d_date_sk
    JOIN store s             ON sa.ss_store_sk   = s.s_store_sk
    JOIN customer c         ON sa.ss_customer_sk = c.c_customer_sk
    JOIN time_dim t         ON sa.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN inventory_agg i ON d.d_date_sk = i.inv_date_sk
  ),
  -- Inventory side for the FULL OUTER JOIN
  inventory_detail AS (
    SELECT
      d.d_date,
      d.d_date_sk,
      i.total_qty
    FROM inventory_agg i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
  )
SELECT
  sf.d_date,
  sf.s_store_name,
  sf.c_first_name,
  sf.c_last_name,
  sf.total_sales,
  sf.sales_cnt,
  COALESCE(sf.total_qty, inv.total_qty) AS total_quantity_on_hand,
  sf.t_hour,
  sf.t_sub_shift
FROM sales_detail sf
FULL OUTER JOIN inventory_detail inv
  ON sf.d_date_sk = inv.d_date_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM web_page_data wp
        WHERE wp.wp_customer_sk = sf.c_customer_sk
          AND wp.wp_creation_date_sk = sf.d_date_sk
      )
  AND sf.s_store_sk IN (SELECT s_store_sk FROM stores_without_sales)
  AND sf.t_sub_shift = 'morning'
ORDER BY sf.total_sales DESC
LIMIT 100
