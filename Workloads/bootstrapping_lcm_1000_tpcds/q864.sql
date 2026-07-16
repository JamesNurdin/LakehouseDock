SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s_closed.s_closed_date_sk AS store_closed_date_sk,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(sr.sr_net_loss) AS total_return_loss,
    COUNT(DISTINCT wp.wp_web_page_id) AS created_pages,
    COUNT(DISTINCT wp_access.wp_web_page_id) AS accessed_pages,
    ROUND((SUM(sr.sr_net_loss) / NULLIF(SUM(ss.ss_net_paid), 0)) * 100, 2) AS return_loss_pct,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY d.d_date) AS day_rank
FROM date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN store s_closed
    ON s_closed.s_closed_date_sk = d.d_date_sk
    AND s_closed.s_store_sk = s.s_store_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_page wp_access
    ON wp_access.wp_access_date_sk = d.d_date_sk
WHERE d.d_year = 2020
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s_closed.s_closed_date_sk,
    s.s_store_sk
ORDER BY total_net_paid DESC
LIMIT 100
