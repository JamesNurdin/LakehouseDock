WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        sd.d_year AS year,
        sd.d_moy AS month,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim sd ON ss.ss_sold_date_sk = sd.d_date_sk
    WHERE sd.d_year = 2001
    GROUP BY ss.ss_store_sk, sd.d_year, sd.d_moy
),
returns_agg AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        rd.d_year AS year,
        rd.d_moy AS month,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim rd ON sr.sr_returned_date_sk = rd.d_date_sk
    WHERE rd.d_year = 2001
    GROUP BY sr.sr_store_sk, rd.d_year, rd.d_moy
)
SELECT
    s.s_store_name,
    sa.year,
    sa.month,
    sa.total_sales,
    COALESCE(ra.total_returns, 0) AS total_returns,
    sa.total_profit - COALESCE(ra.total_return_loss, 0) AS net_profit,
    sa.total_discount / NULLIF(sa.total_sales, 0) AS discount_rate,
    COALESCE(ra.total_returns, 0) / NULLIF(sa.total_sales, 0) AS return_rate
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.store_sk = ra.store_sk
   AND sa.year = ra.year
   AND sa.month = ra.month
JOIN store s
    ON sa.store_sk = s.s_store_sk
ORDER BY net_profit DESC
LIMIT 10
