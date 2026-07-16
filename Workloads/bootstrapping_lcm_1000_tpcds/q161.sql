SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_moy AS month,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_quantity) AS total_sales_quantity,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_net_loss,
    CASE 
        WHEN d_closed.d_date IS NULL THEN 'Open'
        WHEN d.d_date < d_closed.d_date THEN 'Open'
        ELSE 'Closed'
    END AS store_status_at_date,
    ROUND(
        CASE WHEN SUM(ss.ss_quantity) = 0 THEN 0
        ELSE SUM(COALESCE(cr.cr_return_quantity, 0)) * 1.0 / SUM(ss.ss_quantity)
        END,
        4) AS return_quantity_rate,
    ROUND(
        CASE WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
        ELSE SUM(COALESCE(cr.cr_return_amount, 0)) * 1.0 / SUM(ss.ss_ext_sales_price)
        END,
        4) AS return_amount_rate,
    SUM(ss.ss_ext_sales_price) - SUM(COALESCE(cr.cr_return_amount, 0)) AS net_sales_after_returns,
    SUM(ss.ss_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) AS net_profit_after_returns
FROM
    store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE
    d.d_year BETWEEN 2000 AND 2005
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_moy,
    d.d_date,
    d_closed.d_date
HAVING
    SUM(ss.ss_ext_sales_price) > 0
ORDER BY
    net_sales_after_returns DESC
LIMIT 100
