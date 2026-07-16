WITH daily_store_metrics AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        ss.ss_sold_date_sk AS date_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(sr.sr_net_loss) AS total_loss,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(sr.sr_return_quantity) AS total_quantity_returned
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE sr.sr_return_time_sk IN (60517, 52104, 42770)
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY sr.sr_store_sk, ss.ss_sold_date_sk
)
SELECT
    store_sk,
    date_sk,
    total_sales,
    total_return_amount,
    total_profit,
    total_loss,
    CASE WHEN total_sales > 0 THEN (total_profit - total_loss) / total_sales ELSE NULL END AS net_margin,
    CASE WHEN total_quantity_sold > 0 THEN total_quantity_returned * 1.0 / total_quantity_sold ELSE NULL END AS return_rate,
    SUM(total_sales) OVER (PARTITION BY store_sk ORDER BY date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
    AVG(total_profit) OVER (PARTITION BY store_sk ORDER BY date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_profit_last_3_days,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM daily_store_metrics
WHERE total_sales > 0
ORDER BY net_margin DESC
LIMIT 50
