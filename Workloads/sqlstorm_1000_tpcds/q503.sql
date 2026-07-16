WITH
store_sales_agg AS (
  SELECT
    s.s_store_sk,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_net_profit) AS net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    MAX(d.d_date) AS latest_sale_date
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  GROUP BY s.s_store_sk, d.d_year, d.d_month_seq
),
web_sales_agg AS (
  SELECT
    wp.wp_web_page_sk,
    d.d_year,
    d.d_month_seq,
    SUM(ws.ws_net_profit) AS net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
    MAX(d.d_date) AS latest_sale_date
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  GROUP BY wp.wp_web_page_sk, d.d_year, d.d_month_seq
),
combined_sales AS (
  SELECT
    CAST(s_agg.s_store_sk AS VARCHAR) AS entity_id,
    'store' AS entity_type,
    s_agg.d_year,
    s_agg.d_month_seq,
    s_agg.net_profit,
    s_agg.total_sales,
    s_agg.distinct_customers,
    s_agg.latest_sale_date
  FROM store_sales_agg s_agg
  UNION ALL
  SELECT
    CAST(w_agg.wp_web_page_sk AS VARCHAR) AS entity_id,
    'web' AS entity_type,
    w_agg.d_year,
    w_agg.d_month_seq,
    w_agg.net_profit,
    w_agg.total_sales,
    w_agg.distinct_customers,
    w_agg.latest_sale_date
  FROM web_sales_agg w_agg
),
top_entities AS (
  SELECT
    entity_id,
    entity_type,
    d_year,
    d_month_seq,
    net_profit,
    total_sales,
    distinct_customers,
    latest_sale_date,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY net_profit DESC) AS profit_rank,
    SUM(total_sales) OVER (PARTITION BY d_year) AS total_sales_year
  FROM combined_sales
),
store_customers AS (
  SELECT DISTINCT ss_customer_sk AS customer_sk FROM store_sales
),
web_customers AS (
  SELECT DISTINCT ws_bill_customer_sk AS customer_sk FROM web_sales
),
store_only_customers AS (
  SELECT customer_sk FROM store_customers
  EXCEPT
  SELECT customer_sk FROM web_customers
),
web_only_customers AS (
  SELECT customer_sk FROM web_customers
  EXCEPT
  SELECT customer_sk FROM store_customers
),
unique_customers AS (
  SELECT customer_sk, 'store_only' AS uniq_type FROM store_only_customers
  UNION ALL
  SELECT customer_sk, 'web_only' AS uniq_type FROM web_only_customers
)

SELECT
  'entity' AS source_type,
  te.entity_id,
  CONCAT(CASE te.entity_type WHEN 'store' THEN 'Store ' ELSE 'WebPage ' END, te.entity_id) AS entity_desc,
  te.d_year,
  te.d_month_seq,
  COALESCE(te.net_profit, 0) AS net_profit,
  COALESCE(te.total_sales, 0) AS total_sales,
  te.distinct_customers,
  te.latest_sale_date,
  te.profit_rank,
  te.total_sales_year,
  CASE
    WHEN te.profit_rank = 1 THEN 'TOP'
    WHEN te.profit_rank <= 5 THEN 'HIGH'
    ELSE 'OTHER'
  END AS profit_category,
  COALESCE(cc.cc_name, 'N/A') AS call_center_name,
  p.p_promo_name,
  CASE WHEN te.entity_type = 'store' THEN
    (SELECT MAX(cs.cs_order_number)
     FROM catalog_sales cs
     WHERE cs.cs_call_center_sk = CAST(te.entity_id AS INTEGER))
  ELSE NULL END AS recent_order_number
FROM top_entities te
LEFT JOIN call_center cc
  ON cc.cc_call_center_sk = CAST(te.entity_id AS INTEGER) AND te.entity_type = 'store'
LEFT JOIN promotion p
  ON p.p_promo_sk = CAST(te.entity_id AS INTEGER)
WHERE te.profit_rank <= 10

UNION ALL

SELECT
  'unique_customer' AS source_type,
  CAST(uc.customer_sk AS VARCHAR) AS entity_id,
  CONCAT('Customer ', COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, ''), ' [', uc.uniq_type, ']') AS entity_desc,
  CAST(NULL AS INTEGER) AS d_year,
  CAST(NULL AS INTEGER) AS d_month_seq,
  CAST(NULL AS DECIMAL(7,2)) AS net_profit,
  CAST(NULL AS DECIMAL(7,2)) AS total_sales,
  CAST(NULL AS INTEGER) AS distinct_customers,
  CAST(NULL AS DATE) AS latest_sale_date,
  CAST(NULL AS INTEGER) AS profit_rank,
  CAST(NULL AS DECIMAL(7,2)) AS total_sales_year,
  CAST(NULL AS VARCHAR) AS profit_category,
  CAST(NULL AS VARCHAR) AS call_center_name,
  CAST(NULL AS VARCHAR) AS p_promo_name,
  CAST(NULL AS INTEGER) AS recent_order_number
FROM unique_customers uc
LEFT JOIN customer c
  ON uc.customer_sk = c.c_customer_sk
ORDER BY source_type, d_year DESC NULLS LAST, profit_rank
