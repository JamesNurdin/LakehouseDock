WITH sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_cdemo_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
),
returns AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_cdemo_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
)
SELECT
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    SUM(sales.ss_quantity) AS total_quantity_sold,
    SUM(sales.ss_net_paid) AS total_sales_amount,
    SUM(sales.ss_net_profit) AS total_sales_profit,
    SUM(COALESCE(returns.sr_return_quantity, 0)) AS total_quantity_returned,
    SUM(COALESCE(returns.sr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(returns.sr_net_loss, 0)) AS total_return_loss,
    (SUM(sales.ss_net_profit) - SUM(COALESCE(returns.sr_net_loss, 0))) AS net_profit_after_returns
FROM sales
JOIN date_dim d ON sales.ss_sold_date_sk = d.d_date_sk
JOIN store s ON sales.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd ON sales.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN returns ON
    sales.ss_ticket_number = returns.sr_ticket_number
    AND sales.ss_item_sk = returns.sr_item_sk
    AND sales.ss_store_sk = returns.sr_store_sk
    AND sales.ss_cdemo_sk = returns.sr_cdemo_sk
WHERE d.d_date >= DATE '2020-01-01' AND d.d_date <= DATE '2021-12-31'
GROUP BY
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    cd.cd_gender
ORDER BY
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    cd.cd_gender
