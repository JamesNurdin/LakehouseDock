WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_quantity,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE regexp_like(cp.cp_description, '(?i)(sale|discount)')
      AND p.p_channel_details LIKE '%National%'
)
SELECT
    p.p_promo_name,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(fs.cs_net_paid_inc_ship_tax) AS total_net_paid,
    SUM(fs.cs_quantity) AS total_quantity,
    CONCAT('Promo_', REGEXP_EXTRACT(p.p_promo_name, '(\\w+)$')) AS promo_suffix
FROM filtered_sales fs
JOIN date_dim d ON fs.cs_sold_date_sk = d.d_date_sk
JOIN customer c ON fs.cs_bill_customer_sk = c.c_customer_sk
JOIN promotion p ON fs.cs_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1) = 'example.com'
  AND EXISTS (
        SELECT 1
        FROM household_demographics hd
        WHERE hd.hd_demo_sk = c.c_current_hdemo_sk
          AND hd.hd_income_band_sk IS NOT NULL
      )
GROUP BY
    p.p_promo_name,
    CONCAT('Promo_', REGEXP_EXTRACT(p.p_promo_name, '(\\w+)$'))
HAVING SUM(fs.cs_net_paid_inc_ship_tax) > (
        SELECT AVG(cs.cs_net_paid_inc_ship_tax)
        FROM catalog_sales cs
    )
ORDER BY total_net_paid DESC
LIMIT 100
