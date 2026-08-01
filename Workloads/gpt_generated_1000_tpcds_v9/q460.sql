WITH sales_agg AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_wholesale_cost) AS avg_wholesale_cost,
        COUNT(*) AS sales_cnt,
        SUM(CASE WHEN ws.ws_quantity > 5 THEN ws.ws_ext_sales_price ELSE 0 END) AS high_qty_sales
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_wholesale_cost > 30
      AND ws.ws_quantity >= 2
      AND wp.wp_char_count BETWEEN 1000 AND 8000
      AND wp.wp_link_count <= 20
      AND wp.wp_rec_end_date >= DATE '2000-01-01'
    GROUP BY wp.wp_web_page_sk, wp.wp_type
    HAVING SUM(ws.ws_ext_sales_price) > 1000
),
max_sales_cte AS (
    SELECT wp_web_page_sk, MAX(total_sales) AS max_total_sales
    FROM sales_agg
    GROUP BY wp_web_page_sk
),
union_page_sk AS (
    SELECT wp.wp_web_page_sk AS page_sk FROM web_page wp WHERE wp.wp_link_count > 15
    UNION ALL
    SELECT ws.ws_web_page_sk FROM web_sales ws WHERE ws.ws_quantity > 10
)
SELECT
    sa.wp_web_page_sk,
    sa.wp_type,
    sa.total_sales,
    sa.avg_wholesale_cost,
    CASE 
        WHEN sa.total_sales > 5000 THEN 'High'
        WHEN sa.total_sales > 2000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    (
        SELECT MAX(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_web_page_sk = sa.wp_web_page_sk
          AND ws2.ws_net_profit > 0
    ) AS max_positive_profit,
    ms.max_total_sales
FROM sales_agg sa
JOIN max_sales_cte ms ON sa.wp_web_page_sk = ms.wp_web_page_sk
WHERE sa.wp_web_page_sk IN (SELECT page_sk FROM union_page_sk)
  AND EXISTS (
        SELECT 1
        FROM web_sales ws3
        WHERE ws3.ws_web_page_sk = sa.wp_web_page_sk
          AND ws3.ws_ext_sales_price > sa.avg_wholesale_cost * 10
    )
ORDER BY sa.total_sales DESC
LIMIT 100
