WITH sales_union AS (
    -- Catalog sales per customer for 2001 with promotion filter
    SELECT
        c.c_customer_id AS customer_id,
        d.d_year AS sales_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 150000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_promo_sk = cs.cs_promo_sk
              AND p.p_discount_active = 'Y'
        )
    GROUP BY c.c_customer_id, d.d_year

    UNION ALL

    -- Web sales per customer for 2001 with promotion filter
    SELECT
        c.c_customer_id AS customer_id,
        d.d_year AS sales_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        CASE WHEN SUM(ws.ws_ext_sales_price) > 150000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_promo_sk = ws.ws_promo_sk
              AND p.p_discount_active = 'Y'
        )
    GROUP BY c.c_customer_id, d.d_year
)
SELECT DISTINCT
    customer_id,
    sales_year,
    total_sales,
    order_count,
    sales_category,
    RANK() OVER (PARTITION BY sales_year ORDER BY total_sales DESC) AS sales_rank
FROM sales_union
ORDER BY sales_year, sales_rank
LIMIT 100
