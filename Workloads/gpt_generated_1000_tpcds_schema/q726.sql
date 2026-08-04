WITH cs AS (
    SELECT
        cs_order_number,
        cs_bill_customer_sk,
        cs_bill_cdemo_sk,
        cs_bill_addr_sk,
        cs_catalog_page_sk,
        cs_net_paid_inc_tax,
        cs_ext_sales_price
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_net_paid_inc_tax > 500
),
cp AS (
    SELECT
        cp_catalog_page_sk,
        cp_department
    FROM catalog_page
    WHERE cp_department = 'Electronics'
),
customer AS (
    SELECT
        c_customer_sk,
        c_birth_year
    FROM customer
    WHERE c_birth_year BETWEEN 1960 AND 1980
),
ca AS (
    SELECT
        ca_address_sk,
        ca_gmt_offset,
        ca_location_type
    FROM customer_address
    WHERE ca_gmt_offset < -5
),
cd AS (
    SELECT
        cd_demo_sk
    FROM customer_demographics
    WHERE cd_credit_rating = 'Excellent'
),
ss AS (
    SELECT
        ss_customer_sk,
        ss_ext_sales_price
    FROM store_sales
    WHERE ss_sales_price > 20
),
wp AS (
    SELECT
        wp_web_page_sk,
        wp_customer_sk,
        wp_max_ad_count
    FROM web_page
    WHERE wp_max_ad_count <= 2
),
wr AS (
    SELECT
        wr_refunded_customer_sk,
        wr_order_number,
        wr_return_amt
    FROM web_returns
    WHERE wr_return_amt > 0
)
SELECT
    c.c_customer_sk,
    COUNT(DISTINCT cs.cs_order_number)               AS distinct_orders,
    COUNT(DISTINCT wr.wr_order_number)               AS distinct_returns,
    SUM(cs.cs_ext_sales_price)                       AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price)                       AS total_store_sales,
    SUM(wr.wr_return_amt)                            AS total_return_amount,
    CASE WHEN ca.ca_gmt_offset < -7 THEN 'West' ELSE 'East' END AS region,
    l.max_price,
    ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
FROM cs
JOIN cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
FULL OUTER JOIN ss ON ss.ss_customer_sk = c.c_customer_sk
JOIN wp ON wp.wp_customer_sk = c.c_customer_sk
JOIN wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
CROSS JOIN LATERAL (
    SELECT MAX(cs2.cs_ext_sales_price) AS max_price
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
) AS l
WHERE
    ca.ca_location_type = 'condo'
GROUP BY
    c.c_customer_sk,
    ca.ca_gmt_offset,
    CASE WHEN ca.ca_gmt_offset < -7 THEN 'West' ELSE 'East' END,
    l.max_price
ORDER BY sales_rank
LIMIT 100
