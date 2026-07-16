SELECT
    cp.cp_department,
    cp.cp_catalog_page_number,
    cp.cp_catalog_page_id,
    DATE_TRUNC('month', d_sales.d_date) AS sales_month,
    SUM(ss.ss_net_paid) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    (SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0))) AS net_profit_after_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets
FROM
    store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN catalog_page cp
    ON d_sales.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_item_sk = sr.sr_item_sk
LEFT JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
WHERE
    d_sales.d_fy_year = 2001
    AND cp.cp_department = 'DEPARTMENT'
    AND (d_return.d_fy_year = 2001 OR d_return.d_fy_year IS NULL)
GROUP BY
    cp.cp_department,
    cp.cp_catalog_page_number,
    cp.cp_catalog_page_id,
    DATE_TRUNC('month', d_sales.d_date)
HAVING
    SUM(ss.ss_net_paid) > 10000
ORDER BY
    net_profit_after_returns DESC
LIMIT 10
