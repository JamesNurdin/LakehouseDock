WITH
store_monthly AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_moy AS month,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        AVG(sr.sr_return_quantity) AS avg_store_return_qty,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_moy
),
web_monthly AS (
    SELECT
        d.d_year,
        d.d_moy AS month,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        AVG(wr.wr_return_quantity) AS avg_web_return_qty,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY d.d_year, d.d_moy
)
SELECT
    sm.s_store_name,
    sm.s_store_sk,
    sm.d_year,
    sm.month,
    sm.total_store_net_loss,
    COALESCE(wm.total_web_net_loss, 0) AS total_web_net_loss,
    (sm.total_store_net_loss + COALESCE(wm.total_web_net_loss, 0)) AS total_combined_net_loss,
    sm.total_store_return_amt,
    COALESCE(wm.total_web_return_amt, 0) AS total_web_return_amt,
    (sm.total_store_return_amt + COALESCE(wm.total_web_return_amt, 0)) AS total_combined_return_amt,
    sm.avg_store_return_qty,
    COALESCE(wm.avg_web_return_qty, 0) AS avg_web_return_qty,
    sm.store_return_cnt,
    COALESCE(wm.web_return_cnt, 0) AS web_return_cnt,
    (sm.store_return_cnt + COALESCE(wm.web_return_cnt, 0)) AS total_combined_return_cnt,
    RANK() OVER (PARTITION BY sm.d_year, sm.month ORDER BY (sm.total_store_net_loss + COALESCE(wm.total_web_net_loss, 0)) DESC) AS store_month_rank
FROM store_monthly sm
LEFT JOIN web_monthly wm
    ON sm.d_year = wm.d_year
    AND sm.month = wm.month
WHERE (sm.total_store_net_loss + COALESCE(wm.total_web_net_loss, 0)) > 0
ORDER BY sm.d_year, sm.month, store_month_rank
LIMIT 100
