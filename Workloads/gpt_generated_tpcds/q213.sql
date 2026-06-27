/*
  Returns analysis for 2022 – totals and averages per warehouse, refunded address location,
  return reason and month.
*/
WITH returns_last_year AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        d.d_date AS return_date
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
)
SELECT
    w.w_warehouse_name,
    w.w_state AS warehouse_state,
    ca.ca_city AS refunded_city,
    ca.ca_state AS refunded_state,
    r.r_reason_desc,
    DATE_TRUNC('month', rl.return_date) AS month,
    COUNT(*) AS total_returns,
    SUM(rl.cr_return_quantity) AS total_quantity,
    SUM(rl.cr_return_amount) AS total_return_amount,
    SUM(rl.cr_net_loss) AS total_net_loss,
    AVG(rl.cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT rl.cr_refunded_customer_sk) AS distinct_customers
FROM returns_last_year rl
JOIN warehouse w
    ON rl.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON rl.cr_reason_sk = r.r_reason_sk
JOIN customer_address ca
    ON rl.cr_refunded_addr_sk = ca.ca_address_sk
GROUP BY
    w.w_warehouse_name,
    w.w_state,
    ca.ca_city,
    ca.ca_state,
    r.r_reason_desc,
    DATE_TRUNC('month', rl.return_date)
ORDER BY
    w.w_warehouse_name,
    month DESC,
    total_net_loss DESC
