SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    date_format(d_sales.d_date, 'yyyy-MM') AS year_month,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_net_loss,
    AVG(cc.cc_tax_percentage) AS avg_call_center_tax_percentage,
    COUNT(DISTINCT w.wp_web_page_id) AS web_pages_created_on_sales_day
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN call_center cc
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
LEFT JOIN web_page w
    ON w.wp_creation_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year = 2002
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    date_format(d_sales.d_date, 'yyyy-MM')
ORDER BY total_sales_amount DESC
LIMIT 100
