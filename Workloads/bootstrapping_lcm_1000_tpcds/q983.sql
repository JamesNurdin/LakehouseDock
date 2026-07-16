SELECT
    s.s_store_id,
    d_sales.d_quarter_seq,
    CASE WHEN (d_sales.d_quarter_seq % 2) = 0 THEN 'Even' ELSE 'Odd' END AS quarter_parity,
    d_sales.d_current_year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 0 THEN
        COALESCE(SUM(sr.sr_return_amt), 0) / SUM(ss.ss_ext_sales_price)
    ELSE 0 END AS return_rate,
    AVG(wp_c.wp_image_count) AS avg_images_created,
    COUNT(DISTINCT wp_c.wp_web_page_sk) AS distinct_pages_created,
    COUNT(DISTINCT wp_a.wp_web_page_sk) AS distinct_pages_accessed
FROM store s
JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
LEFT JOIN web_page wp_c
    ON wp_c.wp_creation_date_sk = d_sales.d_date_sk
LEFT JOIN web_page wp_a
    ON wp_a.wp_access_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE s.s_closed_date_sk IS NULL OR s.s_closed_date_sk > d_sales.d_date_sk
GROUP BY
    s.s_store_id,
    d_sales.d_quarter_seq,
    CASE WHEN (d_sales.d_quarter_seq % 2) = 0 THEN 'Even' ELSE 'Odd' END,
    d_sales.d_current_year
HAVING SUM(ss.ss_ext_sales_price) > 0
ORDER BY total_sales DESC
LIMIT 100
