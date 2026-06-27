WITH sales AS (
    SELECT
        ss_ticket_number,
        ss_store_sk,
        ss_sold_date_sk,
        ss_quantity,
        ss_net_profit,
        ss_ext_discount_amt
    FROM store_sales
),
returns AS (
    SELECT
        sr_ticket_number,
        sr_return_quantity,
        sr_net_loss
    FROM store_returns
)
SELECT
    s.s_store_name,
    date_trunc('month', d.d_date) AS month,
    sum(sa.ss_net_profit) AS total_net_profit,
    sum(coalesce(re.sr_net_loss, 0)) AS total_net_loss,
    sum(sa.ss_net_profit) - sum(coalesce(re.sr_net_loss, 0)) AS net_profit_after_returns,
    sum(sa.ss_quantity) AS total_quantity_sold,
    sum(coalesce(re.sr_return_quantity, 0)) AS total_quantity_returned,
    (sum(coalesce(re.sr_return_quantity, 0)) * 1.0) / nullif(sum(sa.ss_quantity), 0) AS return_rate,
    avg(sa.ss_ext_discount_amt) AS avg_discount_amount
FROM sales sa
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON sa.ss_sold_date_sk = d.d_date_sk
LEFT JOIN returns re
    ON sa.ss_ticket_number = re.sr_ticket_number
WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
GROUP BY s.s_store_name, date_trunc('month', d.d_date)
ORDER BY s.s_store_name, month
