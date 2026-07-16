WITH catalog_sales_data AS (
    SELECT cs_sold_date_sk AS sale_date_sk,
           cs_call_center_sk AS call_center_sk,
           cs_bill_customer_sk AS cust_sk,
           cs_quantity AS quantity,
           cs_ext_sales_price AS total_sales_price,
           cs_net_profit AS net_profit
    FROM catalog_sales
), store_sales_data AS (
    SELECT ss_sold_date_sk AS sale_date_sk,
           CAST(NULL AS integer) AS call_center_sk,
           ss_customer_sk AS cust_sk,
           ss_quantity AS quantity,
           ss_ext_sales_price AS total_sales_price,
           ss_net_profit AS net_profit
    FROM store_sales
), web_sales_data AS (
    SELECT ws_sold_date_sk AS sale_date_sk,
           CAST(NULL AS integer) AS call_center_sk,
           ws_bill_customer_sk AS cust_sk,
           ws_quantity AS quantity,
           ws_ext_sales_price AS total_sales_price,
           ws_net_profit AS net_profit
    FROM web_sales
), unified_sales AS (
    SELECT * FROM catalog_sales_data
    UNION ALL
    SELECT * FROM store_sales_data
    UNION ALL
    SELECT * FROM web_sales_data
), sales_filtered AS (
    SELECT us.*,
           d.d_year,
           d.d_date
    FROM unified_sales us
    JOIN date_dim d ON us.sale_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
), customer_agg AS (
    SELECT sf.cust_sk,
           SUM(sf.net_profit) AS total_net_profit,
           SUM(sf.total_sales_price) AS total_sales_price,
           SUM(sf.quantity) AS total_quantity,
           COUNT(*) AS sales_count,
           MIN(sf.d_date) AS first_sale_date,
           MAX(sf.d_date) AS last_sale_date
    FROM sales_filtered sf
    GROUP BY sf.cust_sk
), catalog_customers AS (
    SELECT DISTINCT cs_bill_customer_sk AS cust_sk FROM catalog_sales
), web_customers AS (
    SELECT DISTINCT ws_bill_customer_sk AS cust_sk FROM web_sales
), multi_channel_customers AS (
    SELECT cust_sk FROM catalog_customers INTERSECT SELECT cust_sk FROM web_customers
), customer_call_center_map AS (
    SELECT cs_bill_customer_sk AS cust_sk,
           MIN(cs_call_center_sk) AS call_center_sk
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
), customer_details AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
           ca.ca_state,
           ca.ca_city,
           ca.ca_country,
           cc.cc_state,
           cc.cc_name,
           c.c_email_address
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_call_center_map ccm ON c.c_customer_sk = ccm.cust_sk
    LEFT JOIN call_center cc ON ccm.call_center_sk IS NOT DISTINCT FROM cc.cc_call_center_sk
), ranked_customers AS (
    SELECT
        cd.c_customer_sk,
        cd.c_customer_id,
        cd.customer_name,
        COALESCE(cd.cc_state, cd.ca_state, 'UNKNOWN') AS region_state,
        COALESCE(ca.total_net_profit, 0) AS total_net_profit,
        COALESCE(ca.total_sales_price, 0) AS total_sales_price,
        ca.total_quantity AS total_quantity,
        ca.sales_count AS sales_count,
        ca.first_sale_date AS first_sale_date,
        ca.last_sale_date AS last_sale_date,
        ca.total_net_profit / NULLIF(ca.total_sales_price, 0) AS profit_ratio,
        (SELECT AVG(sf.net_profit) FROM sales_filtered sf WHERE sf.cust_sk = cd.c_customer_sk) AS avg_profit_per_sale,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ca.total_net_profit, 0) DESC) AS rank,
        CONCAT('Customer ', cd.c_customer_id,
               ' from ', COALESCE(cd.cc_state, cd.ca_state, 'Unknown'),
               ' - Email: ', COALESCE(cd.c_email_address, 'N/A'),
               ' - Tier: ', CASE WHEN cd.c_email_address LIKE '%@example.com' THEN 'Premium' ELSE 'Standard' END) AS description,
        SUM(COALESCE(ca.total_net_profit, 0)) OVER () AS total_all_customers_profit
    FROM customer_details cd
    LEFT JOIN customer_agg ca ON cd.c_customer_sk = ca.cust_sk
    WHERE cd.c_customer_sk IN (SELECT cust_sk FROM multi_channel_customers)
), top_customers AS (
    SELECT *
    FROM ranked_customers
    WHERE rank <= 10
)
SELECT
    c.c_customer_sk,
    c.c_customer_id,
    c.customer_name,
    c.region_state,
    c.total_net_profit,
    c.total_sales_price,
    c.profit_ratio,
    c.avg_profit_per_sale,
    c.sales_count,
    c.total_quantity,
    c.first_sale_date,
    c.last_sale_date,
    c.rank,
    c.description,
    c.total_all_customers_profit
FROM top_customers c
UNION ALL
SELECT
    cd.c_customer_sk,
    cd.c_customer_id,
    cd.customer_name,
    COALESCE(cd.cc_state, cd.ca_state, 'UNKNOWN') AS region_state,
    CAST(0.0 AS decimal(15,2)) AS total_net_profit,
    CAST(0.0 AS decimal(15,2)) AS total_sales_price,
    CAST(0 AS integer) AS total_quantity,
    CAST(0 AS integer) AS sales_count,
    NULL AS first_sale_date,
    NULL AS last_sale_date,
    NULL AS profit_ratio,
    NULL AS avg_profit_per_sale,
    NULL AS rank,
    CONCAT('No sales for ', cd.customer_name) AS description,
    CAST(0.0 AS decimal(15,2)) AS total_all_customers_profit
FROM customer_details cd
WHERE NOT EXISTS (SELECT 1 FROM customer_agg ca WHERE ca.cust_sk = cd.c_customer_sk)
ORDER BY total_net_profit DESC NULLS LAST, rank
