WITH daily_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_profit) AS daily_sales_profit,
        SUM(ss.ss_ext_sales_price) AS daily_sales_amount,
        COUNT(*) AS daily_sales_txn,
        COUNT(DISTINCT hd.hd_buy_potential) AS distinct_buy_potential_cnt,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
),
 daily_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss) AS daily_return_loss,
        SUM(sr.sr_return_amt_inc_tax) AS daily_return_amount,
        COUNT(*) AS daily_return_txn
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
),
 customer_daily AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        COUNT(DISTINCT cd.cd_credit_rating) AS distinct_credit_rating_cnt,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
),
 combined_daily AS (
    SELECT
        ds.ss_store_sk AS store_sk,
        ds.ss_sold_date_sk AS date_sk,
        ds.daily_sales_profit,
        COALESCE(dr.daily_return_loss, 0) AS daily_return_loss,
        (ds.daily_sales_profit - COALESCE(dr.daily_return_loss, 0)) AS net_daily_profit,
        ds.distinct_buy_potential_cnt,
        ds.avg_vehicle_count,
        cd.distinct_credit_rating_cnt,
        cd.avg_purchase_estimate
    FROM daily_sales ds
    LEFT JOIN daily_returns dr
        ON ds.ss_store_sk = dr.sr_store_sk
        AND ds.ss_sold_date_sk = dr.sr_returned_date_sk
    LEFT JOIN customer_daily cd
        ON ds.ss_store_sk = cd.ss_store_sk
        AND ds.ss_sold_date_sk = cd.ss_sold_date_sk
)
SELECT
    store_sk,
    date_sk,
    net_daily_profit,
    CASE
        WHEN net_daily_profit >= 50000 THEN 'HIGH_PROFIT'
        WHEN net_daily_profit >= 20000 THEN 'MEDIUM_PROFIT'
        ELSE 'LOW_PROFIT'
    END AS profit_category,
    distinct_buy_potential_cnt,
    avg_vehicle_count,
    distinct_credit_rating_cnt,
    avg_purchase_estimate,
    SUM(net_daily_profit) OVER (PARTITION BY store_sk ORDER BY date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    LAG(net_daily_profit, 1, 0) OVER (PARTITION BY store_sk ORDER BY date_sk) AS previous_day_profit,
    CASE
        WHEN net_daily_profit > LAG(net_daily_profit, 1, 0) OVER (PARTITION BY store_sk ORDER BY date_sk) THEN 'INCREASE'
        WHEN net_daily_profit < LAG(net_daily_profit, 1, 0) OVER (PARTITION BY store_sk ORDER BY date_sk) THEN 'DECREASE'
        ELSE 'NO_CHANGE'
    END AS profit_trend
FROM combined_daily
WHERE store_sk IS NOT NULL
ORDER BY store_sk, date_sk DESC
LIMIT 100
