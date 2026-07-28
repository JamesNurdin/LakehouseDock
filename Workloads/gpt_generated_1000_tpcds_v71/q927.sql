WITH cust_store_ret AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        sr.sr_store_sk AS store_sk,
        SUM(sr.sr_net_loss) AS store_return_loss
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE c.c_birth_country = 'CHILE'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_upper_bound <= 80000
    GROUP BY c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, sr.sr_store_sk
),
cust_web_ret AS (
    SELECT
        c.c_customer_sk,
        SUM(wr.wr_net_loss) AS web_return_loss
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE c.c_birth_country = 'CHILE'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_upper_bound <= 80000
    GROUP BY c.c_customer_sk
),
store_info AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_street_type,
        s.s_rec_start_date
    FROM store s
    WHERE s.s_street_type IN ('Dr.', 'Ave')
      AND s.s_rec_start_date >= DATE '2000-01-01'
)
SELECT DISTINCT
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    si.s_store_name,
    cs.store_return_loss,
    cw.web_return_loss,
    (COALESCE(cs.store_return_loss, 0) + COALESCE(cw.web_return_loss, 0)) AS combined_net_loss,
    RANK() OVER (ORDER BY (COALESCE(cs.store_return_loss, 0) + COALESCE(cw.web_return_loss, 0)) DESC) AS loss_rank
FROM cust_store_ret cs
LEFT JOIN cust_web_ret cw ON cs.c_customer_sk = cw.c_customer_sk
LEFT JOIN store_info si ON cs.store_sk = si.s_store_sk
ORDER BY loss_rank, cs.c_customer_id
LIMIT 100
