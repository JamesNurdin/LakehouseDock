WITH sales_filtered AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
)
SELECT
    d.d_year,
    s.s_store_name,
    p.p_promo_name,
    cp.cp_department,
    SUM(sf.cs_quantity)               AS total_units_sold,
    SUM(sf.cs_ext_sales_price)        AS total_sales,
    AVG(sf.cs_net_profit)             AS avg_profit,
    COUNT(DISTINCT sf.cs_bill_customer_sk) AS distinct_customers
FROM sales_filtered sf
-- date dimension for the sold date
JOIN date_dim d ON sf.cs_sold_date_sk = d.d_date_sk
-- catalog page information
JOIN catalog_page cp ON sf.cs_catalog_page_sk = cp.cp_catalog_page_sk
-- promotion information
JOIN promotion p ON sf.cs_promo_sk = p.p_promo_sk
-- optional store information (left outer join)
LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
-- customer who bought the items
JOIN customer c ON sf.cs_bill_customer_sk = c.c_customer_sk
-- inventory data for the same date (used only to bring the table into the query)
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
-- web page activity for the customer
JOIN web_page w ON w.wp_customer_sk = c.c_customer_sk
WHERE d.d_year = 2000
  AND w.wp_image_count >= 4
  AND cp.cp_description LIKE '%women%'
  AND NOT EXISTS (
        SELECT 1
        FROM web_page w2
        WHERE w2.wp_customer_sk = c.c_customer_sk
          AND w2.wp_max_ad_count = 0
    )
GROUP BY d.d_year, s.s_store_name, p.p_promo_name, cp.cp_department
ORDER BY total_sales DESC
LIMIT 100
