WITH refunded AS (
    SELECT
        hd.hd_buy_potential,
        SUM(wr.wr_refunded_cash) AS metric_value,
        'RefundedCash' AS metric_type,
        CASE WHEN SUM(wr.wr_refunded_cash) > 500 THEN 'High' ELSE 'Low' END AS category,
        (SELECT COUNT(DISTINCT r2.r_reason_id)
         FROM reason r2
         WHERE r2.r_reason_desc LIKE '%damaged%') AS extra_info
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%damaged%'
      AND hd.hd_income_band_sk IN (4, 8, 11)
    GROUP BY hd.hd_buy_potential
),
losses AS (
    SELECT
        hd.hd_buy_potential,
        SUM(wr.wr_net_loss) AS metric_value,
        'NetLoss' AS metric_type,
        CASE WHEN SUM(wr.wr_net_loss) > 200 THEN 'High' ELSE 'Low' END AS category,
        CAST(NULL AS integer) AS extra_info
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE NOT r.r_reason_desc LIKE '%damaged%'
      AND EXISTS (
          SELECT 1
          FROM reason r2
          WHERE r2.r_reason_id = r.r_reason_id
            AND r2.r_reason_desc LIKE '%warranty%'
      )
    GROUP BY hd.hd_buy_potential
)
SELECT
    hd_buy_potential,
    metric_value,
    metric_type,
    category,
    extra_info
FROM refunded
UNION ALL
SELECT
    hd_buy_potential,
    metric_value,
    metric_type,
    category,
    extra_info
FROM losses
LIMIT 100
