SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_state,
    cd_sales.cd_gender,
    cd_ret.cd_marital_status AS return_customer_marital_status,
    d_closed.d_current_month AS store_closed_month,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    COUNT(ss.ss_ticket_number) AS sales_transactions,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(cr.cr_order_number) AS return_transactions,
    (SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss)) AS net_profit_after_returns
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd_sales
    ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d.d_year = 2020
  AND s.s_state = 'CA'
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_state,
    cd_sales.cd_gender,
    cd_ret.cd_marital_status,
    d_closed.d_current_month
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
