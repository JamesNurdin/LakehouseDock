WITH cs_agg AS (
  SELECT
    cs_bill_customer_sk AS customer_sk,
    SUM(cs_net_profit) AS total_catalog_profit,
    SUM(cs_quantity) AS total_catalog_quantity,
    SUM(cs_ext_discount_amt) AS total_catalog_discount_amount,
    SUM(cs_ext_sales_price) AS total_catalog_sales_amount
  FROM catalog_sales
  GROUP BY cs_bill_customer_sk
),
ws_agg AS (
  SELECT
    ws_bill_customer_sk AS customer_sk,
    SUM(ws_net_profit) AS total_web_profit,
    SUM(ws_quantity) AS total_web_quantity,
    SUM(ws_ext_discount_amt) AS total_web_discount_amount,
    SUM(ws_ext_sales_price) AS total_web_sales_amount,
    COUNT(DISTINCT ws_web_page_sk) AS distinct_pages_visited,
    SUM(ws_ext_discount_amt) / NULLIF(SUM(ws_ext_sales_price), 0) AS web_discount_rate
  FROM web_sales
  GROUP BY ws_bill_customer_sk
),
wp_agg AS (
  SELECT
    wp_customer_sk AS customer_sk,
    COUNT(DISTINCT wp_web_page_sk) AS total_pages_created,
    COUNT(DISTINCT wp_type) AS distinct_page_types
  FROM web_page
  GROUP BY wp_customer_sk
)
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  COALESCE(cs_agg.total_catalog_profit, 0) AS total_catalog_profit,
  COALESCE(ws_agg.total_web_profit, 0) AS total_web_profit,
  COALESCE(cs_agg.total_catalog_profit, 0) + COALESCE(ws_agg.total_web_profit, 0) AS total_combined_profit,
  RANK() OVER (ORDER BY COALESCE(cs_agg.total_catalog_profit, 0) + COALESCE(ws_agg.total_web_profit, 0) DESC) AS profit_rank,
  COALESCE(cs_agg.total_catalog_quantity, 0) + COALESCE(ws_agg.total_web_quantity, 0) AS total_quantity,
  (COALESCE(cs_agg.total_catalog_discount_amount, 0) + COALESCE(ws_agg.total_web_discount_amount, 0))
    / NULLIF(COALESCE(cs_agg.total_catalog_sales_amount, 0) + COALESCE(ws_agg.total_web_sales_amount, 0), 0) AS overall_discount_rate,
  COALESCE(ws_agg.distinct_pages_visited, 0) AS distinct_web_pages_visited,
  COALESCE(wp_agg.total_pages_created, 0) AS total_pages_created_by_customer,
  COALESCE(wp_agg.distinct_page_types, 0) AS distinct_page_types_created
FROM customer c
LEFT JOIN cs_agg ON cs_agg.customer_sk = c.c_customer_sk
LEFT JOIN ws_agg ON ws_agg.customer_sk = c.c_customer_sk
LEFT JOIN wp_agg ON wp_agg.customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
ORDER BY total_combined_profit DESC
LIMIT 100
