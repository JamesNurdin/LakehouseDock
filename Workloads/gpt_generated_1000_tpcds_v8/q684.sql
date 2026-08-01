WITH
  sales_by_time AS (
    SELECT
      td.t_time_id,
      td.t_meal_time,
      COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
      COUNT(DISTINCT td.t_hour) AS distinct_hours,
      COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_sales
    FROM store_sales ss
    RIGHT OUTER JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_meal_time IN ('lunch', 'dinner')
    GROUP BY td.t_time_id,
             td.t_meal_time
  ),
  promo_sales AS (
    SELECT
      i.i_item_id,
      SUM(ss.ss_ext_sales_price) AS promo_sales,
      COUNT(DISTINCT ss.ss_customer_sk) AS promo_dist_cust,
      CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_level
    FROM store_sales ss
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i
      ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY i.i_item_id
  ),
  returns_by_item AS (
    SELECT
      i.i_item_id,
      SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_item_id
  ),
  combined AS (
    SELECT
      i_item_id AS key,
      promo_sales AS metric1,
      promo_dist_cust AS metric2,
      sales_level AS category
    FROM promo_sales
    UNION
    SELECT
      t_time_id AS key,
      total_sales AS metric1,
      distinct_customers AS metric2,
      t_meal_time AS category
    FROM sales_by_time
  ),
  no_return_keys AS (
    SELECT key FROM combined
    EXCEPT
    SELECT i_item_id FROM returns_by_item
  )
SELECT
  c.key,
  c.metric1,
  c.metric2,
  c.category,
  (SELECT MAX(p_cost) FROM promotion) AS max_promo_cost,
  ROW_NUMBER() OVER (ORDER BY c.metric1 DESC) AS rn
FROM combined c
JOIN no_return_keys nrk
  ON c.key = nrk.key
ORDER BY c.metric1 DESC
LIMIT 100
