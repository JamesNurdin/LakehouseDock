WITH orders_not_in_catalog AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2001
    )
    EXCEPT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
)
SELECT
    s.s_store_id,
    d.d_year,
    cd.cd_gender,
    COUNT(DISTINCT cr.cr_order_number)                         AS catalog_return_orders,
    SUM(ss.ss_net_paid)                                         AS total_store_sales,
    SUM(ws.ws_net_paid)                                         AS total_web_sales,
    AVG(wp_stats.avg_char_count)                               AS avg_page_char_count,
    (SELECT COUNT(*) FROM orders_not_in_catalog)               AS web_orders_not_in_catalog
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
FULL OUTER JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
CROSS JOIN LATERAL (
    SELECT AVG(wp2.wp_char_count) AS avg_char_count
    FROM web_page wp2
    WHERE wp2.wp_web_page_id = wp.wp_web_page_id
) AS wp_stats
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 2001
  AND cd.cd_marital_status = 'M'
  AND s.s_state = 'CA'
  AND wp.wp_type = 'A'
GROUP BY s.s_store_id, d.d_year, cd.cd_gender, wp_stats.avg_char_count
LIMIT 100
