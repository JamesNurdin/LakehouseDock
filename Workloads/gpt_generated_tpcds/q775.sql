WITH sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ds.d_year,
        ds.d_month_seq,
        i.i_category
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ds.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
returns AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_store_sk,
        sr.sr_item_sk,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    WHERE dr.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
)
SELECT
    s.s_store_name,
    sales.d_year,
    sales.d_month_seq,
    sales.i_category,
    sum(sales.ss_net_paid) AS total_sales_net_paid,
    sum(sales.ss_net_profit) AS total_sales_net_profit,
    sum(coalesce(returns.sr_net_loss, 0)) AS total_returns_net_loss,
    sum(sales.ss_net_profit) - sum(coalesce(returns.sr_net_loss, 0)) AS net_profit_after_returns,
    count(distinct sales.ss_customer_sk) AS distinct_customers,
    avg(hd.hd_dep_count) AS avg_dependent_count
FROM sales
JOIN store s ON sales.ss_store_sk = s.s_store_sk
JOIN household_demographics hd ON sales.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN returns ON sales.ss_ticket_number = returns.sr_ticket_number
    AND sales.ss_store_sk = returns.sr_store_sk
    AND sales.ss_item_sk = returns.sr_item_sk
GROUP BY
    s.s_store_name,
    sales.d_year,
    sales.d_month_seq,
    sales.i_category
ORDER BY
    s.s_store_name,
    sales.d_year,
    sales.d_month_seq,
    sales.i_category
