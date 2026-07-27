WITH sales_by_item AS (
    SELECT
        cs.cs_item_sk,
        i.i_item_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_quantity) AS avg_qty
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY cs.cs_item_sk, i.i_item_id
)
SELECT
    cp.cp_department,
    SUBSTRING(cp.cp_description FROM 1 FOR 20) AS short_desc,
    CASE
        WHEN REGEXP_LIKE(cp.cp_description, '[A-Z]{2}[0-9]{3}') THEN 'AlphaNum'
        ELSE 'Other'
    END AS desc_type,
    d.d_year,
    d.d_month_seq,
    CONCAT(cp.cp_department, '-', CAST(d.d_year AS VARCHAR)) AS dept_year,
    SUM(cs.cs_ext_sales_price) AS dept_sales,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    AVG(sbi.total_sales) AS avg_item_sales,
    COUNT(*) FILTER (WHERE ca.ca_city LIKE 'San%') AS san_city_customers
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN sales_by_item sbi ON cs.cs_item_sk = sbi.cs_item_sk
WHERE REGEXP_LIKE(cp.cp_description, '.*[0-9]{3}.*')
  AND ca.ca_location_type = 'single family'
  AND EXISTS (
        SELECT 1 FROM promotion p
        WHERE p.p_promo_sk = cs.cs_promo_sk
          AND REGEXP_LIKE(p.p_promo_name, '^.*Discount.*$')
    )
GROUP BY
    cp.cp_department,
    SUBSTRING(cp.cp_description FROM 1 FOR 20),
    CASE
        WHEN REGEXP_LIKE(cp.cp_description, '[A-Z]{2}[0-9]{3}') THEN 'AlphaNum'
        ELSE 'Other'
    END,
    d.d_year,
    d.d_month_seq,
    CONCAT(cp.cp_department, '-', CAST(d.d_year AS VARCHAR))
ORDER BY dept_sales DESC
LIMIT 100
