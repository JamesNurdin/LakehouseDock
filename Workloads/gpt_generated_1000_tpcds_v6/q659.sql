WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        i.i_brand AS brand,
        wp.wp_type AS page_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_category_id IN (1, 2, 8)
      AND i.i_units IN ('Case', 'Bundle')
      AND wp.wp_image_count >= 4
      AND ws.ws_ext_discount_amt BETWEEN 0 AND 5000
      AND ws.ws_ext_wholesale_cost > 300
    GROUP BY ROLLUP (i.i_category, i.i_brand, wp.wp_type)
)
SELECT
    category,
    brand,
    page_type,
    total_sales,
    total_profit,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_sales DESC) AS sales_rank,
    CASE
        WHEN total_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status
FROM sales_agg
ORDER BY category, sales_rank
LIMIT 100
