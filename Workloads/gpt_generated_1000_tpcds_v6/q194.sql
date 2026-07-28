WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM tpcds.web_sales ws
    WHERE ws.ws_ext_discount_amt > 1000
      AND ws.ws_quantity >= 2
      AND ws.ws_sold_date_sk BETWEEN 2450810 AND 2450820
      AND ws.ws_ext_sales_price > 0
      AND ws.ws_web_site_sk IS NOT NULL
    GROUP BY ws.ws_web_site_sk, ws.ws_web_page_sk
)
SELECT
    sa.ws_web_site_sk,
    site.web_name,
    wp.wp_type,
    sa.total_sales,
    sa.order_cnt,
    sa.total_discount,
    RANK() OVER (PARTITION BY site.web_name ORDER BY sa.total_sales DESC) AS sales_rank,
    CASE WHEN wp.wp_autogen_flag = 'Y' THEN 'Auto' ELSE 'Manual' END AS page_origin,
    EXISTS (
        SELECT 1
        FROM tpcds.web_page wp2
        WHERE wp2.wp_web_page_sk = sa.ws_web_page_sk
          AND wp2.wp_char_count > 500
    ) AS has_large_page
FROM sales_agg sa
JOIN tpcds.web_site site
    ON sa.ws_web_site_sk = site.web_site_sk
LEFT JOIN tpcds.web_page wp
    ON sa.ws_web_page_sk = wp.wp_web_page_sk
WHERE site.web_gmt_offset BETWEEN -8.00 AND -5.00
  AND site.web_state = 'CA'
  AND site.web_close_date_sk > 2445000
  AND wp.wp_autogen_flag IS NOT NULL
  AND (wp.wp_type = 'content' OR wp.wp_type = 'advertisement')
ORDER BY sa.total_sales DESC
LIMIT 100
