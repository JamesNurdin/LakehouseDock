WITH page_sales AS (
    SELECT
        cp.cp_catalog_page_sk,
        COUNT(cs.cs_order_number) AS orders,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        REGEXP_EXTRACT(cp.cp_description, '(\\d{3})') AS three_digit_code,
        CASE
            WHEN REGEXP_LIKE(cp.cp_description, '^.*[Ff]ree.*$') THEN 'Free'
            ELSE 'Paid'
        END AS price_type
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    GROUP BY cp.cp_catalog_page_sk, cp.cp_description
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    COALESCE(ps.orders, 0) AS orders,
    COALESCE(ps.total_net_paid, 0) AS total_net_paid,
    ps.price_type,
    COALESCE(ps.three_digit_code, 'N/A') AS code,
    CONCAT(cp.cp_department, '-', cp.cp_type) AS dept_type,
    CASE
        WHEN cp.cp_type LIKE 'P%' THEN 'Promo'
        ELSE 'Regular'
    END AS type_group,
    (
        SELECT AVG(i_current_price)
        FROM item
        WHERE i_brand = cp.cp_department
    ) AS avg_brand_price
FROM catalog_page cp
RIGHT OUTER JOIN page_sales ps
    ON cp.cp_catalog_page_sk = ps.cp_catalog_page_sk
WHERE cp.cp_start_date_sk IS NOT NULL
  AND (cp.cp_description LIKE '%sale%' OR REGEXP_LIKE(cp.cp_description, '.*\\d{3}.*'))
ORDER BY total_net_paid DESC, cp.cp_catalog_page_id
LIMIT 100
