WITH sales AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_promo_sk AS promo_sk,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_store_sk, ss.ss_promo_sk, d.d_year
),
returns AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        ss.ss_promo_sk AS promo_sk,
        d.d_year AS year,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = ss.ss_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_store_sk, ss.ss_promo_sk, d.d_year
)
SELECT
    s.s_store_name,
    p.p_promo_name,
    sales.year,
    sales.total_net_paid,
    sales.total_net_profit,
    COALESCE(returns.total_return_amt, 0) AS total_return_amount,
    sales.total_net_paid - COALESCE(returns.total_return_amt, 0) AS net_sales_after_returns
FROM sales
JOIN store s ON sales.store_sk = s.s_store_sk
JOIN promotion p ON sales.promo_sk = p.p_promo_sk
LEFT JOIN returns ON returns.store_sk = sales.store_sk
    AND returns.promo_sk = sales.promo_sk
    AND returns.year = sales.year
ORDER BY s.s_store_name, p.p_promo_name
