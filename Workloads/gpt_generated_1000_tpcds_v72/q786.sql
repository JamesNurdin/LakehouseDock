WITH agg AS (
    SELECT
        s.s_division_id AS division_id,
        r.r_reason_desc AS reason_desc,
        hd.hd_buy_potential AS buy_potential,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        MAX(sr.sr_return_amt) AS max_return_amt
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE hd.hd_buy_potential IN ('>10000', '1001-5000')
      AND s.s_hours = '8AM-12AM'
      AND sr.sr_return_amt > 500
    GROUP BY s.s_division_id, r.r_reason_desc, hd.hd_buy_potential
)
SELECT
    division_id,
    reason_desc,
    buy_potential,
    num_returns,
    total_return_amt,
    avg_return_amt,
    max_return_amt,
    SUM(total_return_amt) OVER (PARTITION BY division_id) AS division_total_return_amt,
    RANK() OVER (PARTITION BY division_id ORDER BY total_return_amt DESC) AS rank_by_return
FROM agg
ORDER BY division_id, total_return_amt DESC
LIMIT 100
