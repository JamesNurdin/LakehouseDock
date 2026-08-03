WITH
  /* Filter stores whose key appears in the list of warehouse keys used in returns */
  filtered_store AS (
    SELECT *
    FROM store
    WHERE s_store_sk IN (
      SELECT DISTINCT cr_warehouse_sk
      FROM catalog_returns
      WHERE cr_warehouse_sk IS NOT NULL
    )
  ),

  /* Right‑outer join between items (dimension) and sales (fact) – keeps every item */
  item_sales AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      i.i_current_price,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_sold_date_sk,
      ss.ss_customer_sk,
      ss.ss_hdemo_sk,
      ss.ss_store_sk
    FROM item i
    RIGHT OUTER JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
  )

SELECT
  s.s_store_name,
  d.d_year,
  SUM(cr.cr_return_amount)                                   AS total_return_amount,
  SUM(t.sales_amount)                                        AS total_sales_amount,
  AVG(isales.i_current_price)                                AS avg_item_price,
  COUNT(DISTINCT c.c_customer_id)                            AS unique_customers,
  MIN(w.w_warehouse_sq_ft)                                   AS min_warehouse_sq_ft,
  MAX(sm.sm_code)                                            AS max_ship_code
FROM filtered_store s
FULL OUTER JOIN web_page wp
  ON wp.wp_creation_date_sk = s.s_closed_date_sk               -- uses the only allowed join rule involving web_page and date_dim via the store’s closed date surrogate
LEFT JOIN date_dim d
  ON d.d_date_sk = s.s_closed_date_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN item_sales isales
  ON isales.ss_sold_date_sk = d.d_date_sk
  AND isales.ss_store_sk = s.s_store_sk
CROSS JOIN LATERAL (
  SELECT SUM(ss2.ss_net_paid) AS sales_amount
  FROM store_sales ss2
  WHERE ss2.ss_store_sk = s.s_store_sk
) t
WHERE d.d_year = 2002                                     -- predicate 1
  AND isales.i_current_price > 20.00                     -- predicate 2
  AND sm.sm_code = 'AIR'                                 -- predicate 3
  AND c.c_preferred_cust_flag = 'Y'                      -- predicate 4
GROUP BY
  s.s_store_name,
  d.d_year

UNION

SELECT
  s.s_store_name,
  d.d_year,
  SUM(cr.cr_return_amount)                                   AS total_return_amount,
  SUM(t.sales_amount)                                        AS total_sales_amount,
  AVG(isales.i_current_price)                                AS avg_item_price,
  COUNT(DISTINCT c.c_customer_id)                            AS unique_customers,
  MIN(w.w_warehouse_sq_ft)                                   AS min_warehouse_sq_ft,
  MAX(sm.sm_code)                                            AS max_ship_code
FROM filtered_store s
FULL OUTER JOIN web_page wp
  ON wp.wp_creation_date_sk = s.s_closed_date_sk
LEFT JOIN date_dim d
  ON d.d_date_sk = s.s_closed_date_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN item_sales isales
  ON isales.ss_sold_date_sk = d.d_date_sk
  AND isales.ss_store_sk = s.s_store_sk
CROSS JOIN LATERAL (
  SELECT SUM(ss2.ss_net_paid) AS sales_amount
  FROM store_sales ss2
  WHERE ss2.ss_store_sk = s.s_store_sk
) t
WHERE d.d_year = 2001                                     -- predicate 1 (different year)
  AND isales.i_current_price BETWEEN 10 AND 30          -- predicate 2 (different price range)
  AND sm.sm_code = 'SEA'                                 -- predicate 3 (different ship mode)
  AND c.c_preferred_cust_flag = 'N'                      -- predicate 4 (different flag)
GROUP BY
  s.s_store_name,
  d.d_year

ORDER BY
  s_store_name,
  d_year
LIMIT 100
