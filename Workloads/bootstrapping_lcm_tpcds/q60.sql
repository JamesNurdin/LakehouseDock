SELECT
    s.s_store_name,
    s.s_city,
    ds.d_date AS sales_date,
    ca.ca_city AS sales_address_city,
    ca_ret.ca_city AS returning_address_city,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_returns,
    SUM(ss.ss_ext_sales_price) - SUM(COALESCE(wr.wr_return_amt, 0)) AS net_sales_minus_returns,
    dc.d_date AS store_closed_date,
    dc.d_current_year AS store_closed_year,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns
FROM store_sales ss
JOIN date_dim ds
    ON ss.ss_sold_date_sk = ds.d_date_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim dc
    ON s.s_closed_date_sk = dc.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = ds.d_date_sk
    AND wr.wr_refunded_addr_sk = ca.ca_address_sk
LEFT JOIN customer_address ca_ret
    ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    ds.d_date,
    ca.ca_city,
    ca_ret.ca_city,
    dc.d_date,
    dc.d_current_year
ORDER BY total_sales DESC
LIMIT 100
