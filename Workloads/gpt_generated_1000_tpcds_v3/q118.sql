WITH filtered_sales AS (
    SELECT
        cs.cs_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_ext_discount_amt AS ext_discount_amt,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        c.c_email_address AS email_address,
        ca.ca_city AS city,
        ca.ca_state AS state
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(p.p_promo_name, '^Promo[0-9]+')
      AND c.c_email_address LIKE '%@example.com'
),
aggregated_sales AS (
    SELECT
        promo_sk,
        promo_name,
        first_name,
        last_name,
        city,
        state,
        SUM(ext_sales_price) AS total_sales,
        SUM(ext_discount_amt) AS total_discount
    FROM filtered_sales
    GROUP BY promo_sk, promo_name, first_name, last_name, city, state
    HAVING SUM(ext_sales_price) > 50000
)
SELECT
    a.promo_sk,
    a.promo_name,
    regexp_extract(a.promo_name, 'Promo([0-9]+)', 1) AS promo_code,
    CONCAT(a.first_name, ' ', a.last_name) AS full_name,
    a.city,
    a.state,
    a.total_sales,
    a.total_discount,
    CASE
        WHEN a.total_sales >= 100000 THEN 'High'
        WHEN a.total_sales >= 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY a.promo_sk ORDER BY a.total_sales DESC) AS sales_rank,
    (SELECT AVG(cs2.cs_ext_discount_amt)
     FROM catalog_sales cs2
     WHERE cs2.cs_promo_sk = a.promo_sk) AS avg_discount_per_promo
FROM aggregated_sales a
ORDER BY a.total_sales DESC
LIMIT 100
