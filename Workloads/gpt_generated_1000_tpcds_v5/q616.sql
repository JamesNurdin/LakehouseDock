WITH store_ret AS (
    SELECT
        'store' AS return_source,
        s.s_store_name AS store_name,
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS total_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 50000
    GROUP BY s.s_store_name, r.r_reason_desc
),
web_ret AS (
    SELECT
        'web' AS return_source,
        NULL AS store_name,
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_net_loss) AS total_loss
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 50000
    GROUP BY r.r_reason_desc
)
SELECT
    return_source,
    store_name,
    reason_desc,
    total_loss,
    CASE WHEN total_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category
FROM store_ret
UNION ALL
SELECT
    return_source,
    store_name,
    reason_desc,
    total_loss,
    CASE WHEN total_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category
FROM web_ret
ORDER BY total_loss DESC
LIMIT 100
