WITH
  intersect_items AS (
    SELECT i_item_sk FROM item
    WHERE i_color IN ('red', 'lime')
      AND i_manager_id > 20
    INTERSECT
    SELECT ss_item_sk FROM store_sales
    WHERE ss_quantity > 5
  ),
  sales_filtered AS (
    SELECT
      ss.ss_sold_date_sk AS sold_date_sk,
      ss.ss_item_sk AS item_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      d.d_year,
      i.i_category,
      i.i_color,
      ca.ca_state
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND i.i_category_id = 7
  ),
  returns_filtered AS (
    SELECT
      cr.cr_returned_date_sk AS returned_date_sk,
      cr.cr_item_sk AS item_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      d2.d_year,
      i2.i_category,
      i2.i_color,
      ca2.ca_state,
      sm.sm_type AS ship_mode_type
    FROM catalog_returns cr
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca2 ON cr.cr_refunded_addr_sk = ca2.ca_address_sk
    WHERE cr.cr_item_sk IN (SELECT i_item_sk FROM intersect_items)
      AND sm.sm_type = 'AIR'
      AND d2.d_year BETWEEN 2000 AND 2002
  ),
  full_data AS (
    SELECT
      COALESCE(s.item_sk, r.item_sk)                                         AS item_sk,
      COALESCE(s.d_year, r.d_year)                                           AS year,
      COALESCE(s.i_category, r.i_category)                                   AS i_category,
      COALESCE(s.i_color, r.i_color)                                         AS i_color,
      COALESCE(s.ca_state, r.ca_state)                                       AS ca_state,
      r.ship_mode_type,
      s.ss_quantity,
      s.ss_net_paid,
      r.cr_return_quantity,
      r.cr_return_amount
    FROM sales_filtered s
    FULL OUTER JOIN returns_filtered r
      ON s.item_sk = r.item_sk
     AND s.sold_date_sk = r.returned_date_sk
  ),
  aggregated AS (
    SELECT
      item_sk,
      year,
      i_category,
      i_color,
      ca_state,
      ship_mode_type,
      SUM(ss_quantity)            AS total_quantity,
      SUM(ss_net_paid)            AS total_sales,
      SUM(cr_return_quantity)     AS total_return_qty,
      SUM(cr_return_amount)       AS total_return_amount
    FROM full_data
    GROUP BY GROUPING SETS (
      (item_sk, year, i_category, i_color, ca_state, ship_mode_type),
      (item_sk, year, i_category, i_color, ca_state),
      (item_sk, year),
      (item_sk),
      ()
    )
  ),
  final AS (
    SELECT
      item_sk,
      year,
      i_category,
      i_color,
      ca_state,
      ship_mode_type,
      total_quantity,
      total_sales,
      total_return_qty,
      total_return_amount,
      ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_sales DESC) AS sales_rank,
      CASE
        WHEN total_sales > 10000 THEN 'High'
        WHEN total_sales > 5000  THEN 'Medium'
        ELSE 'Low'
      END AS sales_category
    FROM aggregated
    WHERE item_sk IS NOT NULL
  )
SELECT
  item_sk,
  year,
  i_category,
  i_color,
  ca_state,
  ship_mode_type,
  total_quantity,
  total_sales,
  total_return_qty,
  total_return_amount,
  sales_rank,
  sales_category
FROM final
ORDER BY year DESC, sales_rank
LIMIT 100
