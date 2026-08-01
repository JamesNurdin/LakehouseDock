/* goal: Analyze customer financial activity by combining store sales, catalog returns, and web page activity, applying filters, aggregating metrics, and selecting top customers. */
WITH
  /* Sample a fraction of store_sales */
  sales_base AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  /* Aggregate store sales per customer with several filters */
  sales_agg AS (
    SELECT
      c.c_customer_id AS customer_id,
      SUM(ssb.ss_net_paid) AS total_sales,
      COUNT(*) AS sales_cnt,
      SUM(ssb.ss_quantity) AS total_quantity
    FROM sales_base ssb
    JOIN date_dim d ON ssb.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ssb.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p ON ssb.ss_promo_sk = p.p_promo_sk
    LEFT JOIN household_demographics hd ON ssb.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca ON ssb.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON ssb.ss_ticket_number = sr.sr_ticket_number
    WHERE d.d_year = 2001
      AND p.p_channel_press = 'N'
      AND hd.hd_vehicle_count >= 1
      AND ca.ca_state = 'CA'
    GROUP BY c.c_customer_id
  ),
  /* Aggregate catalog returns per customer with its own filters */
  catalog_agg AS (
    SELECT
      c.c_customer_id AS customer_id,
      -SUM(cr.cr_return_amount) AS total_refund,
      COUNT(*) AS refund_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cp.cp_type = 'Online'
      AND d.d_month_seq = 1212
      AND cp.cp_department = 'Books'
      AND ca.ca_country = 'United States'
    GROUP BY c.c_customer_id
  ),
  /* Web page activity per customer */
  web_agg AS (
    SELECT
      c.c_customer_id AS customer_id,
      COUNT(*) AS web_page_views,
      SUM(wp.wp_char_count) AS total_chars
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_fy_year = 2001
      AND wp.wp_type = 'Content'
    GROUP BY c.c_customer_id
  ),
  /* Union of sales and catalog aggregates (distinct) */
  union_agg AS (
    SELECT customer_id, total_sales AS metric_amount, sales_cnt AS metric_cnt
    FROM sales_agg
    UNION DISTINCT
    SELECT customer_id, total_refund AS metric_amount, refund_cnt AS metric_cnt
    FROM catalog_agg
  ),
  /* Intersection of customer IDs appearing in both sales and catalog data */
  intersect_ids AS (
    SELECT customer_id
    FROM sales_agg
    INTERSECT
    SELECT customer_id
    FROM catalog_agg
  )
SELECT
  ua.customer_id,
  ua.metric_amount,
  ua.metric_cnt,
  COALESCE(wa.web_page_views, 0) AS web_page_views,
  lt.lateral_total,
  (
    SELECT COUNT(*)
    FROM store_returns sr
    WHERE sr.sr_customer_sk = c.c_customer_sk
  ) AS store_return_cnt
FROM union_agg ua
JOIN customer c ON ua.customer_id = c.c_customer_id
LEFT JOIN web_agg wa ON wa.customer_id = c.c_customer_id
LEFT JOIN LATERAL (
  SELECT SUM(ss2.ss_ext_sales_price) AS lateral_total
  FROM store_sales ss2
  WHERE ss2.ss_customer_sk = c.c_customer_sk
) lt ON TRUE
WHERE ua.customer_id IN (SELECT customer_id FROM intersect_ids)
ORDER BY ua.metric_amount DESC
LIMIT 100
