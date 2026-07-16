SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    d.d_date,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT cr.cr_order_number) AS return_transactions,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    (SUM(ss.ss_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0)) AS net_profit_after_returns,
    RANK() OVER (ORDER BY (SUM(ss.ss_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0)) DESC) AS profit_rank,
    COUNT(DISTINCT ca_sales.ca_address_sk) AS distinct_sales_addresses,
    COUNT(DISTINCT ca_refunded.ca_address_sk) AS distinct_refunded_addresses,
    COUNT(DISTINCT ca_returning.ca_address_sk) AS distinct_returning_addresses
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
       AND s.s_closed_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_sales
    ON ss.ss_addr_sk = ca_sales.ca_address_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
GROUP BY s.s_store_id, s.s_city, s.s_state, d.d_date
ORDER BY net_profit_after_returns DESC
LIMIT 100
