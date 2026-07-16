SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_id,
    s.s_city,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amount,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    AVG(cr.cr_fee) AS avg_catalog_fee,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_return_net_loss
FROM date_dim d
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
    AND ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
WHERE d.d_year = 2023
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_id,
    s.s_city
ORDER BY total_sales_amount DESC
LIMIT 100
