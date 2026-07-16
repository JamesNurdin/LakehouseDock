WITH web_sales_agg AS (
    SELECT ws_sold_date_sk AS date_sk,
           SUM(ws_net_paid_inc_tax) AS sales_amount,
           SUM(ws_net_profit) AS profit
    FROM web_sales
    GROUP BY ws_sold_date_sk
),
web_returns_agg AS (
    SELECT wr_returned_date_sk AS date_sk,
           SUM(wr_refunded_cash + wr_return_amt_inc_tax) AS return_amount,
           SUM(wr_net_loss) AS return_loss
    FROM web_returns
    GROUP BY wr_returned_date_sk
),
catalog_sales_agg AS (
    SELECT cs_sold_date_sk AS date_sk,
           SUM(cs_net_paid_inc_tax) AS sales_amount,
           SUM(cs_net_profit) AS profit
    FROM catalog_sales
    GROUP BY cs_sold_date_sk
),
catalog_returns_agg AS (
    SELECT cr_returned_date_sk AS date_sk,
           SUM(cr_refunded_cash + cr_return_amt_inc_tax) AS return_amount,
           SUM(cr_net_loss) AS return_loss
    FROM catalog_returns
    GROUP BY cr_returned_date_sk
),
store_sales_agg AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_store_sk,
           SUM(ss_net_paid_inc_tax) AS sales_amount,
           SUM(ss_net_profit) AS profit
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_store_sk
),
store_returns_agg AS (
    SELECT sr_returned_date_sk AS date_sk,
           sr_store_sk,
           SUM(sr_refunded_cash + sr_return_amt_inc_tax) AS return_amount,
           SUM(sr_net_loss) AS return_loss
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_store_sk
),
combined_all AS (
    SELECT COALESCE(ws.date_sk, wr.date_sk) AS date_sk,
           d.d_date,
           'Web' AS channel,
           COALESCE(ws.sales_amount, 0) AS sales_amount,
           COALESCE(ws.profit, 0) AS profit,
           COALESCE(wr.return_amount, 0) AS return_amount,
           COALESCE(wr.return_loss, 0) AS return_loss
    FROM web_sales_agg ws
    FULL OUTER JOIN web_returns_agg wr ON ws.date_sk = wr.date_sk
    JOIN date_dim d ON COALESCE(ws.date_sk, wr.date_sk) = d.d_date_sk

    UNION ALL

    SELECT COALESCE(cs.date_sk, cr.date_sk) AS date_sk,
           d.d_date,
           'Catalog' AS channel,
           COALESCE(cs.sales_amount, 0) AS sales_amount,
           COALESCE(cs.profit, 0) AS profit,
           COALESCE(cr.return_amount, 0) AS return_amount,
           COALESCE(cr.return_loss, 0) AS return_loss
    FROM catalog_sales_agg cs
    FULL OUTER JOIN catalog_returns_agg cr ON cs.date_sk = cr.date_sk
    JOIN date_dim d ON COALESCE(cs.date_sk, cr.date_sk) = d.d_date_sk

    UNION ALL

    SELECT COALESCE(ss.date_sk, sr.date_sk) AS date_sk,
           d.d_date,
           'Store' AS channel,
           COALESCE(ss.sales_amount, 0) AS sales_amount,
           COALESCE(ss.profit, 0) AS profit,
           COALESCE(sr.return_amount, 0) AS return_amount,
           COALESCE(sr.return_loss, 0) AS return_loss
    FROM store_sales_agg ss
    FULL OUTER JOIN store_returns_agg sr ON ss.date_sk = sr.date_sk AND ss.ss_store_sk = sr.sr_store_sk
    JOIN date_dim d ON COALESCE(ss.date_sk, sr.date_sk) = d.d_date_sk
)
SELECT
    c.d_date,
    c.channel,
    CONCAT('Channel ', UPPER(c.channel), ' on ', CAST(c.d_date AS VARCHAR)) AS label,
    c.sales_amount,
    c.return_amount,
    (c.sales_amount - c.return_amount) AS net_sales_balance,
    c.profit,
    c.return_loss,
    (c.profit - c.return_loss) AS net_profit_balance,
    CASE
        WHEN (c.sales_amount - c.return_amount) >= 1000000 THEN 'High'
        WHEN (c.sales_amount - c.return_amount) >= 500000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_level,
    SUM(c.sales_amount - c.return_amount) OVER (PARTITION BY c.channel ORDER BY c.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS sales_7day_sum,
    AVG(c.profit - c.return_loss) OVER (PARTITION BY c.channel ORDER BY c.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS profit_7day_avg,
    ROW_NUMBER() OVER (PARTITION BY c.d_date ORDER BY (c.profit - c.return_loss) DESC) AS profit_rank,
    LAG(c.profit - c.return_loss) OVER (PARTITION BY c.channel ORDER BY c.d_date) AS prev_day_profit,
    CASE
        WHEN LAG(c.profit - c.return_loss) OVER (PARTITION BY c.channel ORDER BY c.d_date) IS NULL THEN NULL
        ELSE ((c.profit - c.return_loss) - LAG(c.profit - c.return_loss) OVER (PARTITION BY c.channel ORDER BY c.d_date))
               / NULLIF(LAG(c.profit - c.return_loss) OVER (PARTITION BY c.channel ORDER BY c.d_date), 0) * 100
    END AS profit_change_pct,
    CASE
        WHEN c.channel = 'Web' THEN (SELECT MAX(ws2.ws_net_profit) FROM web_sales ws2 WHERE ws2.ws_sold_date_sk <= c.date_sk)
        WHEN c.channel = 'Catalog' THEN (SELECT MAX(cs2.cs_net_profit) FROM catalog_sales cs2 WHERE cs2.cs_sold_date_sk <= c.date_sk)
        WHEN c.channel = 'Store' THEN (SELECT MAX(ss2.ss_net_profit) FROM store_sales ss2 WHERE ss2.ss_sold_date_sk <= c.date_sk)
        ELSE NULL
    END AS max_txn_profit_to_date
FROM combined_all c
WHERE c.d_date >= DATE '2022-01-01'
  AND (c.sales_amount > 0 OR c.return_amount > 0)
ORDER BY c.d_date DESC, c.channel
