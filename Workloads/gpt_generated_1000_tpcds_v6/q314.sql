WITH sr_agg AS (
    SELECT
        sr_reason_sk,
        SUM(sr_net_loss) AS total_store_loss,
        AVG(sr_fee) AS avg_store_fee,
        COUNT(*) AS store_ret_cnt
    FROM store_returns
    WHERE sr_fee > 20
      AND sr_net_loss > 0
    GROUP BY sr_reason_sk
),
wr_agg AS (
    SELECT
        wr_reason_sk,
        SUM(wr_net_loss) AS total_web_loss,
        AVG(wr_return_ship_cost) AS avg_ship_cost,
        COUNT(*) AS web_ret_cnt
    FROM web_returns
    WHERE wr_return_ship_cost > 500
      AND wr_return_quantity >= 2
    GROUP BY wr_reason_sk
)
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    COALESCE(sr.total_store_loss, 0) AS store_loss,
    COALESCE(wr.total_web_loss, 0) AS web_loss,
    (COALESCE(sr.total_store_loss, 0) + COALESCE(wr.total_web_loss, 0)) AS combined_loss,
    ROW_NUMBER() OVER (PARTITION BY r.r_reason_id ORDER BY (COALESCE(sr.total_store_loss, 0) + COALESCE(wr.total_web_loss, 0)) DESC) AS rn,
    CASE
        WHEN COALESCE(sr.store_ret_cnt, 0) > 100 THEN 'High Store Volume'
        WHEN COALESCE(wr.web_ret_cnt, 0) > 100 THEN 'High Web Volume'
        ELSE 'Normal'
    END AS volume_category
FROM reason r
LEFT JOIN sr_agg sr ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN wr_agg wr ON wr.wr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%price%'
  AND r.r_reason_id IN (
        SELECT r2.r_reason_id
        FROM reason r2
        WHERE r2.r_reason_sk BETWEEN 1 AND 10
    )
  AND (COALESCE(sr.total_store_loss, 0) + COALESCE(wr.total_web_loss, 0)) > 1000
  AND (COALESCE(sr.avg_store_fee, 0) < 50 OR COALESCE(wr.avg_ship_cost, 0) > 600)
ORDER BY combined_loss DESC
LIMIT 100
