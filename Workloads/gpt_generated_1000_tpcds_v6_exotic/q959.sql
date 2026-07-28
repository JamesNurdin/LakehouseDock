WITH sales_a AS (
    SELECT
        w.w_warehouse_name,
        p.wp_type,
        CASE
            WHEN s.ws_ext_discount_amt > 100 THEN 'High Discount'
            ELSE 'Standard'
        END AS discount_category,
        SUM(s.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count
    FROM web_sales s
    JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page p ON s.ws_web_page_sk = p.wp_web_page_sk
    WHERE w.w_county = 'Marshall County'
      AND p.wp_type = 'home'
    GROUP BY w.w_warehouse_name,
        p.wp_type,
        CASE
            WHEN s.ws_ext_discount_amt > 100 THEN 'High Discount'
            ELSE 'Standard'
        END
),
sales_b AS (
    SELECT
        w.w_warehouse_name,
        p.wp_type,
        CASE
            WHEN s.ws_ext_discount_amt > 100 THEN 'High Discount'
            ELSE 'Standard'
        END AS discount_category,
        SUM(s.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count
    FROM web_sales s
    JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page p ON s.ws_web_page_sk = p.wp_web_page_sk
    WHERE w.w_county = 'Richland County'
      AND p.wp_rec_start_date BETWEEN DATE '2000-09-03' AND DATE '2001-09-03'
    GROUP BY w.w_warehouse_name,
        p.wp_type,
        CASE
            WHEN s.ws_ext_discount_amt > 100 THEN 'High Discount'
            ELSE 'Standard'
        END
)
SELECT
    w_warehouse_name,
    wp_type,
    discount_category,
    total_sales,
    order_count
FROM sales_a
UNION ALL
SELECT
    w_warehouse_name,
    wp_type,
    discount_category,
    total_sales,
    order_count
FROM sales_b
LIMIT 100
