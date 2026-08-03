WITH
    store_profit AS (
        SELECT
            s.s_store_sk,
            s.s_store_id,
            s.s_store_name,
            SUM(ss.ss_net_profit) AS total_net_profit,
            CASE WHEN SUM(ss.ss_net_profit) > 100000 THEN 'High' ELSE 'Medium' END AS profit_category
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name
    ),
    store_loss AS (
        SELECT
            sr.sr_store_sk AS sr_store_sk,
            SUM(sr.sr_net_loss) AS total_net_loss,
            CASE WHEN SUM(sr.sr_net_loss) > 80000 THEN 'HighLoss' ELSE 'LowLoss' END AS loss_category
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY sr.sr_store_sk
        HAVING SUM(sr.sr_net_loss) > 50000
    )
SELECT
    sp.s_store_id,
    sp.s_store_name,
    sp.total_net_profit,
    sp.profit_category,
    sl.total_net_loss,
    sl.loss_category,
    CASE WHEN sp.total_net_profit > (SELECT AVG(total_net_profit) FROM store_profit) THEN 'AboveAvg' ELSE 'BelowAvg' END AS profit_vs_avg
FROM store_profit sp
JOIN store_loss sl ON sp.s_store_sk = sl.sr_store_sk
WHERE sp.s_store_sk IN (
    SELECT sp2.s_store_sk
    FROM store_profit sp2
    WHERE sp2.total_net_profit > (SELECT AVG(total_net_profit) FROM store_profit)
    INTERSECT
    SELECT sl2.sr_store_sk
    FROM store_loss sl2
)
  AND EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_store_sk = sp.s_store_sk
          AND sr3.sr_return_quantity > 0
    )
ORDER BY sp.total_net_profit DESC
LIMIT 100
