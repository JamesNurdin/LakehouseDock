/*
Goal: Produce a store‑level sales performance snapshot that combines in‑store, catalog and web channels, applies realistic filters, uses set operations (INTERSECT / EXCEPT), a scalar subquery, a CASE expression, and samples the store_sales fact.
*/
WITH
  /* Sampled in‑store sales */
  ss AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_quantity > 1
  ),
  /* Order numbers from catalog sales meeting a net‑paid threshold */
  cs_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_net_paid > 1000
  ),
  /* Order numbers from web sales meeting a net‑paid threshold */
  ws_orders AS (
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_net_paid > 500
  ),
  /* Orders that appear in both catalog and web channels */
  intersect_orders AS (
    SELECT ws_order_number FROM ws_orders
    INTERSECT
    SELECT cs_order_number FROM cs_orders
  ),
  /* Orders that are in catalog sales but not in web sales */
  except_orders AS (
    SELECT cs_order_number FROM cs_orders
    EXCEPT
    SELECT ws_order_number FROM ws_orders
  ),
  /* Core fact with all required dimensions and additional filters */
  filtered_ss AS (
    SELECT
      ss.*,
      i.i_category,
      p.p_discount_active,
      s.s_street_type,
      s.s_suite_number,
      s.s_rec_end_date,
      t.t_hour,
      cs.cs_order_number    AS cs_order_number,
      ws.ws_order_number    AS ws_order_number,
      wp.wp_web_page_sk,
      wr.wr_returned_time_sk
    FROM ss
    JOIN item i          ON ss.ss_item_sk      = i.i_item_sk
    JOIN promotion p      ON ss.ss_promo_sk     = p.p_promo_sk
    JOIN store s          ON ss.ss_store_sk     = s.s_store_sk
    JOIN time_dim t       ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN catalog_sales cs
           ON cs.cs_item_sk      = i.i_item_sk
          AND cs.cs_sold_time_sk = t.t_time_sk
          AND cs.cs_promo_sk    = p.p_promo_sk
    LEFT JOIN web_sales ws
           ON ws.ws_item_sk      = i.i_item_sk
          AND ws.ws_sold_time_sk = t.t_time_sk
          AND ws.ws_promo_sk    = p.p_promo_sk
    LEFT JOIN web_page wp
           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
           ON wr.wr_item_sk          = i.i_item_sk
          AND wr.wr_returned_time_sk = t.t_time_sk
          AND wr.wr_web_page_sk     = wp.wp_web_page_sk
          AND wr.wr_order_number    = ws.ws_order_number
    WHERE i.i_category          = 'Electronics'
      AND p.p_discount_active  = 'Y'
      AND s.s_street_type      = 'Avenue'
      AND s.s_suite_number     = 'Suite T'
      AND s.s_rec_end_date    > DATE '2000-01-01'
      AND t.t_hour BETWEEN 8 AND 12
  )
SELECT
  s.s_store_id,
  i.i_category,
  COUNT(DISTINCT ss.ss_ticket_number)                                   AS num_tickets,
  SUM(ss.ss_ext_sales_price)                                            AS total_sales,
  AVG(ss.ss_ext_discount_amt)                                           AS avg_discount,
  MIN(ss.ss_ext_sales_price)                                            AS min_sale,
  MAX(ss.ss_ext_sales_price)                                            AS max_sale,
  CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_level,
  (SELECT COUNT(*) FROM intersect_orders)                               AS intersect_order_count,
  (SELECT COUNT(*) FROM except_orders)                                  AS except_order_count
FROM filtered_ss ss
JOIN store s      ON ss.ss_store_sk = s.s_store_sk
JOIN item i       ON ss.ss_item_sk = i.i_item_sk
GROUP BY s.s_store_id, i.i_category
ORDER BY total_sales DESC
LIMIT 100
