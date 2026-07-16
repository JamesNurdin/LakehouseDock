WITH returns_by_store AS (
    SELECT
        sr_store_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS num_returns,
        AVG(sr_return_quantity) AS avg_quantity
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2451545 AND 2451910
      AND sr_return_amt > 0
    GROUP BY sr_store_sk
)
SELECT
    cc.cc_division,
    cc.cc_market_manager,
    cc.cc_state,
    rbs.total_return_amt,
    rbs.total_net_loss,
    rbs.num_returns,
    ROUND(rbs.avg_quantity, 2) AS avg_quantity,
    RANK() OVER (PARTITION BY cc.cc_division ORDER BY rbs.total_return_amt DESC) AS division_rank
FROM call_center cc
JOIN returns_by_store rbs
  ON cc.cc_call_center_sk = rbs.sr_store_sk
WHERE cc.cc_country = 'United States'
  AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
  AND cc.cc_rec_start_date <= DATE '2022-12-31'
  AND cc.cc_rec_end_date >= DATE '2022-01-01'
ORDER BY cc.cc_division, division_rank
LIMIT 100
