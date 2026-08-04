WITH
    agg_page_sales AS (
        SELECT
            wp.wp_web_page_sk,
            wp.wp_url,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            SUM(ws.ws_quantity) AS total_qty,
            AVG(ws.ws_list_price) AS avg_list_price
        FROM tpcds.web_sales ws
        JOIN tpcds.web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE wp.wp_image_count >= 3
          AND wp.wp_char_count BETWEEN 2000 AND 6000
          AND ws.ws_list_price > 50
          AND ws.ws_wholesale_cost < 60
        GROUP BY wp.wp_web_page_sk, wp.wp_url
    ),
    high_sales_pages AS (
        SELECT wp_web_page_sk
        FROM agg_page_sales
        WHERE total_sales > 100000
    ),
    low_sales_pages AS (
        SELECT wp_web_page_sk
        FROM agg_page_sales
        WHERE total_sales < 50000
    ),
    target_pages AS (
        SELECT wp_web_page_sk
        FROM high_sales_pages
        EXCEPT
        SELECT wp_web_page_sk
        FROM low_sales_pages
    )
SELECT
    ap.wp_url,
    ap.total_sales,
    ap.total_qty,
    ap.avg_list_price,
    (
        SELECT MAX(ws2.ws_list_price)
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_web_page_sk = ap.wp_web_page_sk
    ) AS max_list_price_for_page
FROM agg_page_sales ap
JOIN target_pages tp
    ON ap.wp_web_page_sk = tp.wp_web_page_sk
WHERE ap.avg_list_price > 60
GROUP BY ap.wp_url, ap.total_sales, ap.total_qty, ap.avg_list_price, ap.wp_web_page_sk
HAVING SUM(ap.total_qty) > 10
ORDER BY ap.total_sales DESC
LIMIT 20
