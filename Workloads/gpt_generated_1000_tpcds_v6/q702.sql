WITH sales_agg AS (
    SELECT
        ws_web_page_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM tpcds.web_sales
    WHERE ws_wholesale_cost > 30
      AND ws_quantity > 1
      AND ws_ext_sales_price IS NOT NULL
    GROUP BY ws_web_page_sk
),
page_filtered AS (
    SELECT
        wp_web_page_sk,
        wp_web_page_id,
        wp_type,
        wp_rec_end_date,
        wp_max_ad_count
    FROM tpcds.web_page
    WHERE wp_rec_end_date >= DATE '2000-01-01'
      AND wp_max_ad_count <= 3
      AND wp_type IN ('Home', 'Product')
)
SELECT
    DISTINCT p.wp_web_page_id,
    p.wp_type,
    s.total_sales,
    s.total_quantity,
    s.avg_discount,
    CASE
        WHEN s.total_sales > 10000 THEN 'BIG'
        WHEN s.total_sales > 5000 THEN 'MEDIUM'
        ELSE 'SMALL'
    END AS sales_size,
    RANK() OVER (PARTITION BY p.wp_type ORDER BY s.total_sales DESC) AS sales_rank_by_type
FROM page_filtered p
JOIN sales_agg s
    ON s.ws_web_page_sk = p.wp_web_page_sk
WHERE s.avg_discount < 5
  AND p.wp_max_ad_count >= 0
ORDER BY s.total_sales DESC
LIMIT 100
