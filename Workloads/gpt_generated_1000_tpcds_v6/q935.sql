WITH sr AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_hdemo_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_reason_sk, sr.sr_hdemo_sk
),
ws AS (
    SELECT
        ws.ws_bill_hdemo_sk AS hd_demo_sk,
        ws.ws_warehouse_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales_amt,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    GROUP BY ws.ws_bill_hdemo_sk, ws.ws_warehouse_sk
)
SELECT
    s.s_store_id,
    s.s_state,
    r.r_reason_id,
    hd.hd_vehicle_count,
    sr.total_return_amt,
    ws.total_sales_amt,
    CASE
        WHEN sr.total_return_amt > 5000 THEN 'High'
        WHEN sr.total_return_amt > 2000 THEN 'Medium'
        ELSE 'Low'
    END AS return_category,
    (SELECT AVG(sr_inner.sr_return_amt)
     FROM store_returns sr_inner
     WHERE sr_inner.sr_reason_sk = r.r_reason_sk) AS avg_return_per_reason,
    RANK() OVER (PARTITION BY s.s_state ORDER BY sr.total_return_amt DESC) AS state_return_rank
FROM sr
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN ws
    ON ws.hd_demo_sk = hd.hd_demo_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE r.r_reason_id IN ('AAAAAAAABAAAAAAA','AAAAAAAABBAAAAAA')
  AND hd.hd_vehicle_count > 0
  AND w.w_zip = '33604'
ORDER BY s.s_state, state_return_rank
LIMIT 100
