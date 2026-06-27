WITH sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_promo_sk
    FROM store_sales ss
),
returns_agg AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_item_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM store_returns sr
    GROUP BY sr.sr_ticket_number, sr.sr_item_sk
)
SELECT
    s.s_store_name,
    date_trunc('month', d.d_date) AS month,
    SUM(sa.ss_ext_sales_price) AS total_sales_amount,
    SUM(sa.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT sa.ss_promo_sk) AS distinct_promotions,
    COALESCE(SUM(rt.total_return_amt_inc_tax), 0) AS total_return_amount,
    SUM(sa.ss_net_profit) - COALESCE(SUM(rt.total_return_amt_inc_tax), 0) AS net_profit_after_returns
FROM sales sa
LEFT JOIN returns_agg rt
    ON sa.ss_ticket_number = rt.sr_ticket_number
    AND sa.ss_item_sk = rt.sr_item_sk
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON sa.ss_sold_date_sk = d.d_date_sk
WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
GROUP BY s.s_store_name, date_trunc('month', d.d_date)
ORDER BY s.s_store_name, month
