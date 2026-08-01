WITH filtered_sales AS (
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_ticket_number,
        ss.ss_wholesale_cost,
        ss.ss_ext_tax,
        ss.ss_net_paid
    FROM store_sales ss
    WHERE ss.ss_wholesale_cost > 30.00
      AND ss.ss_ext_tax < 200.00
),
filtered_returns AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_refunded_cash,
        cr.cr_net_loss,
        cr.cr_order_number,
        cr.cr_warehouse_sk
    FROM catalog_returns cr
    WHERE cr.cr_refunded_cash > 500.00
      AND cr.cr_return_amount > 100.00
)
SELECT
    td.t_hour,
    td.t_am_pm,
    wh.w_warehouse_name,
    COUNT(DISTINCT fs.ss_ticket_number) AS sales_transactions,
    SUM(fs.ss_net_paid) AS total_sales_net_paid,
    AVG(fs.ss_ext_tax) AS avg_sales_tax,
    SUM(fr.cr_return_amount) AS total_return_amount,
    COUNT(fr.cr_order_number) AS total_returns,
    MIN(fr.cr_net_loss) AS min_net_loss,
    MAX(fr.cr_net_loss) AS max_net_loss
FROM filtered_sales fs
JOIN time_dim td ON fs.ss_sold_time_sk = td.t_time_sk
JOIN filtered_returns fr ON fr.cr_returned_time_sk = td.t_time_sk
JOIN warehouse wh ON fr.cr_warehouse_sk = wh.w_warehouse_sk
WHERE td.t_am_pm = 'PM'
  AND td.t_second = 14
GROUP BY td.t_hour, td.t_am_pm, wh.w_warehouse_name
ORDER BY total_sales_net_paid DESC
LIMIT 100
