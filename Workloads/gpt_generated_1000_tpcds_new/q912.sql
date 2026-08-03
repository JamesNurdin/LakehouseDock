WITH store_agg AS (
    SELECT
        sr_reason_sk,
        SUM(sr_return_quantity) AS total_qty,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 1
      AND sr_return_amt > 10
      AND sr_store_credit >= 2
      AND sr_cdemo_sk IN (1136688, 561709, 1637606)
      AND sr_return_time_sk BETWEEN 5000 AND 8000
      AND sr_return_ship_cost IS NOT NULL
    GROUP BY sr_reason_sk
),
high_loss AS (
    SELECT DISTINCT sr_reason_sk FROM store_returns WHERE sr_net_loss > 200
),
low_loss AS (
    SELECT DISTINCT sr_reason_sk FROM store_returns WHERE sr_net_loss < 50
)
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    s.total_qty,
    s.total_return_amt,
    s.total_net_loss,
    RANK() OVER (PARTITION BY r.r_reason_desc ORDER BY s.total_return_amt DESC) AS return_amt_rank,
    CASE WHEN s.total_qty > 100 THEN 'HIGH_VOLUME' ELSE 'NORMAL_VOLUME' END AS volume_category
FROM store_agg s
JOIN reason r ON s.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%service%'
  AND s.total_return_amt > (SELECT AVG(sr_return_amt) FROM store_returns)
  AND r.r_reason_id IN (SELECT r_reason_id FROM reason WHERE r_reason_desc LIKE '%size%')
  AND NOT EXISTS (SELECT 1 FROM low_loss ll WHERE ll.sr_reason_sk = s.sr_reason_sk)
  AND s.sr_reason_sk IN (SELECT sr_reason_sk FROM high_loss)
  AND s.total_net_loss > 0
EXCEPT
SELECT
    r2.r_reason_id,
    r2.r_reason_desc,
    s2.total_qty,
    s2.total_return_amt,
    s2.total_net_loss,
    RANK() OVER (PARTITION BY r2.r_reason_desc ORDER BY s2.total_return_amt DESC),
    CASE WHEN s2.total_qty > 100 THEN 'HIGH_VOLUME' ELSE 'NORMAL_VOLUME' END
FROM store_agg s2
JOIN reason r2 ON s2.sr_reason_sk = r2.r_reason_sk
WHERE r2.r_reason_desc LIKE '%size%'
ORDER BY total_return_amt DESC
OFFSET 10 LIMIT 100
