WITH sales_page AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        ws.ws_ship_mode_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ext_wholesale_cost,
        wp.wp_type
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_ship_mode_sk IN (1, 6, 10)
      AND ws.ws_bill_hdemo_sk = 6410
      AND ws.ws_ext_wholesale_cost > 500
      AND wp.wp_type = 'Content'
)
SELECT
    web_site.web_state,
    sales_page.wp_type,
    CASE WHEN sales_page.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    SUM(sales_page.ws_net_paid) AS total_net_paid,
    AVG(sales_page.ws_ext_sales_price) AS avg_ext_sales_price,
    COUNT(*) AS order_count,
    MIN(sales_page.ws_sold_date_sk) AS min_sold_date_sk,
    MAX(sales_page.ws_sold_date_sk) AS max_sold_date_sk
FROM sales_page
JOIN tpcds.web_site web_site
    ON sales_page.ws_web_site_sk = web_site.web_site_sk
WHERE web_site.web_county = 'Marshall County'
  AND sales_page.ws_sold_date_sk BETWEEN 2452570 AND 2452580
GROUP BY
    web_site.web_state,
    sales_page.wp_type,
    CASE WHEN sales_page.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END
ORDER BY total_net_paid DESC
LIMIT 100
