WITH sales_agg AS (
   SELECT
       cs_bill_customer_sk AS cust_sk,
       SUM(cs_net_paid) AS total_sales,
       COUNT(*) AS num_orders
   FROM catalog_sales
   WHERE cs_net_paid > 0
   GROUP BY cs_bill_customer_sk
),
returns_agg AS (
   SELECT
       cr_refunded_customer_sk AS cust_sk,
       SUM(cr_return_amount) AS total_return_amount,
       COUNT(*) AS num_returns
   FROM catalog_returns
   GROUP BY cr_refunded_customer_sk
)
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_zip,
    s.total_sales,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    (s.total_sales - COALESCE(r.total_return_amount, 0)) AS net_sales,
    SUBSTR(c.c_email_address, 1, 5) AS email_prefix,
    REGEXP_EXTRACT(wp.wp_url, '(https?://[^/]+)/', 1) AS domain
FROM sales_agg s
JOIN customer c
    ON s.cust_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN returns_agg r
    ON s.cust_sk = r.cust_sk
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    REGEXP_LIKE(c.c_first_name, '^[AJ].*')
    AND ca.ca_zip LIKE '9%'
    AND (ca.ca_location_type IS NOT NULL AND ca.ca_location_type <> '')
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
          AND REGEXP_LIKE(r.r_reason_desc, '(?i)damage')
    )
ORDER BY net_sales DESC
LIMIT 100
