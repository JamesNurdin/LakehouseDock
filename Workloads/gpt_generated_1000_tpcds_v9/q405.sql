WITH sales_page AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_net_paid,
        cp.cp_department,
        cp.cp_catalog_page_id,
        cp.cp_start_date_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_catalog_page_id = 'AAAAAAAABBAAAAAA'
      AND cs.cs_net_paid > 500.00
      AND cp.cp_start_date_sk = 2450935
)
SELECT
    c.c_birth_country,
    s.cp_department,
    COUNT(*) AS order_count,
    SUM(s.cs_net_paid) AS total_net_paid,
    AVG(s.cs_net_paid) AS avg_net_paid,
    SUM(CASE WHEN s.cs_net_paid > 1000 THEN s.cs_net_paid ELSE 0 END) AS high_net_paid,
    MIN(s.cs_net_paid) AS min_net_paid,
    MAX(s.cs_net_paid) AS max_net_paid
FROM sales_page s
JOIN customer c
    ON s.cs_bill_customer_sk = c.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM web_page wp
    WHERE wp.wp_customer_sk = c.c_customer_sk
      AND wp.wp_type = 'dynamic'
      AND wp.wp_link_count >= 15
)
  AND NOT EXISTS (
    SELECT 1
    FROM web_page wp2
    WHERE wp2.wp_customer_sk = c.c_customer_sk
      AND wp2.wp_type = 'ad'
)
GROUP BY c.c_birth_country, s.cp_department
ORDER BY total_net_paid DESC
LIMIT 100
