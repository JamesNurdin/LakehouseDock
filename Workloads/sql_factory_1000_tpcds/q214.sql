WITH sales_daily AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
),
returns_daily AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_transactions
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    date_add('day', sd.ss_sold_date_sk, DATE '1970-01-01') AS sale_date,
    sd.total_sales_profit,
    rd.total_return_loss,
    (COALESCE(sd.total_sales_profit, 0) - COALESCE(rd.total_return_loss, 0)) AS net_daily_profit,
    SUM(COALESCE(sd.total_sales_profit, 0) - COALESCE(rd.total_return_loss, 0)) OVER (PARTITION BY s.s_store_id ORDER BY date_add('day', sd.ss_sold_date_sk, DATE '1970-01-01')) AS cumulative_net_profit,
    RANK() OVER (PARTITION BY date_add('day', sd.ss_sold_date_sk, DATE '1970-01-01') ORDER BY (COALESCE(sd.total_sales_profit, 0) - COALESCE(rd.total_return_loss, 0)) DESC) AS daily_store_rank,
    CASE WHEN (COALESCE(sd.total_sales_profit, 0) - COALESCE(rd.total_return_loss, 0)) < 0 THEN 'Loss' ELSE 'Profit' END AS profit_indicator
FROM store s
LEFT JOIN sales_daily sd ON s.s_store_sk = sd.ss_store_sk
LEFT JOIN returns_daily rd ON s.s_store_sk = rd.sr_store_sk AND sd.ss_sold_date_sk = rd.sr_returned_date_sk
WHERE s.s_store_id IS NOT NULL
ORDER BY s.s_store_id, sale_date
