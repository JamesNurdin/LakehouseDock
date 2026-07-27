WITH filtered AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_tax,
        sr.sr_refunded_cash,
        sr.sr_net_loss,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
        AND c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count IN (2, 3, 5)
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_buy_potential = '>10000'
      AND sr.sr_return_tax > 30.00
      AND sr.sr_refunded_cash < 200.00
      AND ib.ib_lower_bound >= 40000
      AND r.r_reason_id = 'R001'
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(sr_refunded_cash) AS total_refunded_cash,
    AVG(sr_return_tax) AS avg_return_tax,
    SUM(CASE WHEN sr_net_loss > 100 THEN sr_net_loss ELSE 0 END) AS high_loss_total,
    COUNT(*) AS total_returns
FROM filtered
GROUP BY ib_lower_bound, ib_upper_bound, hd_buy_potential
ORDER BY total_refunded_cash DESC
LIMIT 100
