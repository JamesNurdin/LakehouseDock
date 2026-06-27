WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_promo_sk AS promo_sk,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_store_sk, ss.ss_promo_sk, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_promo_sk AS promo_sk,
        d.d_year AS year,
        d.d_moy AS month,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_net_loss) AS total_return_net_loss,
        SUM(sr.sr_fee) AS total_return_fee
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_store_sk, ss.ss_promo_sk, d.d_year, d.d_moy
)
SELECT
    st.s_store_name,
    p.p_promo_name,
    CONCAT(CAST(sales.year AS VARCHAR), '-', LPAD(CAST(sales.month AS VARCHAR), 2, '0')) AS month,
    sales.total_quantity,
    sales.total_net_profit,
    COALESCE(returns.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(returns.total_return_net_loss, 0) AS total_return_net_loss,
    (sales.total_net_profit - COALESCE(returns.total_return_net_loss, 0)) AS net_profit_after_returns,
    (sales.total_discount + COALESCE(returns.total_return_fee, 0)) AS total_discount_and_fees
FROM sales_agg sales
LEFT JOIN returns_agg returns
    ON sales.store_sk = returns.store_sk
   AND sales.promo_sk = returns.promo_sk
   AND sales.year = returns.year
   AND sales.month = returns.month
JOIN store st
    ON sales.store_sk = st.s_store_sk
JOIN promotion p
    ON sales.promo_sk = p.p_promo_sk
ORDER BY st.s_store_name, month, p.p_promo_name
