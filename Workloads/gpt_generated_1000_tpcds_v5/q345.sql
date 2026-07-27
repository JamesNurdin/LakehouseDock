WITH store_ret_agg AS (
    SELECT
        sr_store_sk,
        sr_reason_sk,
        sr_hdemo_sk,
        SUM(sr_return_amt) AS total_store_return_amt,
        SUM(sr_net_loss) AS total_store_net_loss,
        COUNT(*) AS cnt_store_returns
    FROM store_returns
    WHERE sr_return_amt > 100
    GROUP BY sr_store_sk, sr_reason_sk, sr_hdemo_sk
)
SELECT
    s.s_store_id,
    s.s_city,
    r.r_reason_desc,
    hd.hd_dep_count,
    hd.hd_income_band_sk,
    agg.total_store_return_amt,
    agg.cnt_store_returns,
    agg.total_store_net_loss,
    CASE WHEN agg.total_store_net_loss > 5000 THEN 'HIGH' ELSE 'NORMAL' END AS loss_category,
    (
        SELECT AVG(wr_sub.wr_return_amt)
        FROM web_returns wr_sub
        WHERE wr_sub.wr_reason_sk = agg.sr_reason_sk
          AND wr_sub.wr_return_amt > 50
    ) AS avg_web_return_amt_for_reason,
    ROW_NUMBER() OVER (PARTITION BY s.s_city ORDER BY agg.total_store_net_loss DESC) AS city_loss_rank
FROM store_ret_agg agg
JOIN store s
    ON agg.sr_store_sk = s.s_store_sk
JOIN reason r
    ON agg.sr_reason_sk = r.r_reason_sk
JOIN household_demographics hd
    ON agg.sr_hdemo_sk = hd.hd_demo_sk
JOIN web_returns wr
    ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    AND wr.wr_reason_sk = agg.sr_reason_sk
WHERE hd.hd_dep_count >= 2
  AND hd.hd_income_band_sk IN (1, 7, 10)
  AND s.s_city = 'Springfield'
  AND s.s_division_id = 1
  AND r.r_reason_desc LIKE '%product%'
  AND wr.wr_return_amt > 50
ORDER BY agg.total_store_net_loss DESC, s.s_store_id
LIMIT 100
