SELECT
    d.d_year,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_quantity) AS total_units_sold,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(sr.sr_return_quantity) AS total_return_units,
    SUM(sr.sr_net_loss) AS total_store_return_net_loss,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_return_quantity) AS total_catalog_return_units,
    SUM(cr.cr_net_loss) AS total_catalog_return_net_loss,
    (SUM(ss.ss_net_profit) - SUM(sr.sr_net_loss) - SUM(cr.cr_net_loss)) AS net_profit_after_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets
FROM date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
    AND s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_store_sk = s.s_store_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY d.d_year, s.s_store_id, s.s_store_name, s.s_city, s.s_state
ORDER BY d.d_year, total_sales_amount DESC
LIMIT 100
