WITH sales_by_promo AS (
    SELECT
        p.p_promo_name,
        d.d_year,
        w.w_warehouse_name,
        wp.wp_url,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        REGEXP_EXTRACT(p.p_channel_details, '(\\w+)', 1) AS first_word,
        REGEXP_LIKE(p.p_channel_details, '[A-Z]') AS has_upper,
        SUBSTRING(w.w_city, 1, 3) AS city_prefix
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE REGEXP_LIKE(p.p_channel_details, '\\b[A-Z][a-z]+\\b')
      AND wp.wp_url LIKE '%.com%'
      AND EXISTS (
            SELECT 1
            FROM inventory inv
            WHERE inv.inv_warehouse_sk = w.w_warehouse_sk
              AND inv.inv_quantity_on_hand > 0
          )
    GROUP BY
        p.p_promo_name,
        d.d_year,
        w.w_warehouse_name,
        wp.wp_url,
        REGEXP_EXTRACT(p.p_channel_details, '(\\w+)', 1),
        REGEXP_LIKE(p.p_channel_details, '[A-Z]'),
        SUBSTRING(w.w_city, 1, 3)
)
SELECT
    s.p_promo_name,
    s.d_year,
    s.w_warehouse_name,
    s.city_prefix,
    s.total_sales,
    s.unique_customers,
    s.first_word,
    s.total_sales / NULLIF(s.unique_customers, 0) AS avg_sales_per_customer,
    RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS sales_rank,
    (
        SELECT AVG(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = s.d_year
    ) AS avg_yearly_sales
FROM sales_by_promo s
ORDER BY s.d_year DESC, s.total_sales DESC
LIMIT 100
