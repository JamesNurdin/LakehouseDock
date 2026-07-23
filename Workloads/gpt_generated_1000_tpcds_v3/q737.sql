WITH filtered_items AS (
    SELECT i_item_sk, i_brand_id, i_category, i_product_name
    FROM item
    WHERE i_rec_start_date >= DATE '2001-01-01'
      AND i_brand_id IN (6008007, 10008011, 1004002)
),
store_customers AS (
    SELECT DISTINCT ss.ss_customer_sk AS customer_sk, fi.i_brand_id, fi.i_category
    FROM store_sales ss
    JOIN filtered_items fi ON ss.ss_item_sk = fi.i_item_sk
),
web_customers AS (
    SELECT DISTINCT ws.ws_bill_customer_sk AS customer_sk, fi.i_brand_id, fi.i_category
    FROM web_sales ws
    JOIN filtered_items fi ON ws.ws_item_sk = fi.i_item_sk
),
return_customers AS (
    SELECT DISTINCT cr.cr_returning_customer_sk AS customer_sk, fi.i_brand_id, fi.i_category
    FROM catalog_returns cr
    JOIN filtered_items fi ON cr.cr_item_sk = fi.i_item_sk
)
SELECT 'Store' AS channel,
       sc.i_brand_id,
       sc.i_category,
       COUNT(*) AS distinct_customers
FROM store_customers sc
GROUP BY sc.i_brand_id, sc.i_category
UNION ALL
SELECT 'Web' AS channel,
       wc.i_brand_id,
       wc.i_category,
       COUNT(*) AS distinct_customers
FROM web_customers wc
GROUP BY wc.i_brand_id, wc.i_category
UNION ALL
SELECT 'Return' AS channel,
       rc.i_brand_id,
       rc.i_category,
       COUNT(*) AS distinct_customers
FROM return_customers rc
GROUP BY rc.i_brand_id, rc.i_category
ORDER BY distinct_customers DESC
LIMIT 100
