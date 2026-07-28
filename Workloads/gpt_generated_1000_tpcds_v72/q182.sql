/* goal: Analyze combined store and web return amounts by reason and household buying potential, applying multiple filters, subtotal rows, and ranking the total returns */
WITH filtered AS (
    SELECT
        sr.sr_reason_sk,
        sr.sr_hdemo_sk,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_return_ship_cost,
        wr.wr_return_amt,
        wr.wr_account_credit,
        wr.wr_refunded_hdemo_sk,
        r.r_reason_desc,
        hd_store.hd_buy_potential AS store_buy_pot,
        hd_store.hd_dep_count,
        hd_web.hd_buy_potential AS web_buy_pot,
        hd_web.hd_vehicle_count
    FROM store_returns sr
    JOIN household_demographics hd_store
          ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
    JOIN reason r
          ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
          ON sr.sr_reason_sk = wr.wr_reason_sk
    JOIN household_demographics hd_web
          ON wr.wr_refunded_hdemo_sk = hd_web.hd_demo_sk
    WHERE sr.sr_fee > 5                                           -- filter 1
      AND sr.sr_return_ship_cost BETWEEN 100 AND 700               -- filter 2
      AND hd_store.hd_dep_count <= 5                               -- filter 3
      AND hd_web.hd_vehicle_count >= 1                             -- filter 4
      AND r.r_reason_desc LIKE '%defect%'                         -- filter 5
      AND wr.wr_account_credit < 500                               -- filter 6
      AND wr.wr_return_amt > 0                                    -- filter 7
)
SELECT
    r_reason_desc,
    store_buy_pot,
    web_buy_pot,
    SUM(sr_return_amt)               AS sum_store_return_amt,
    SUM(wr_return_amt)               AS sum_web_return_amt,
    SUM(sr_return_amt) + SUM(wr_return_amt) AS total_return_amt,
    COUNT(*)                         AS txn_count,
    RANK() OVER (ORDER BY SUM(sr_return_amt) + SUM(wr_return_amt) DESC) AS return_rank
FROM filtered
GROUP BY ROLLUP (r_reason_desc, store_buy_pot, web_buy_pot)
HAVING (SUM(sr_return_amt) + SUM(wr_return_amt)) > 1000
ORDER BY total_return_amt DESC
LIMIT 100
