WITH store_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_amt) AS store_return_amt,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
),
web_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_amt) AS web_return_amt,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
)
SELECT
    COALESCE(sa.ib_income_band_sk, wa.ib_income_band_sk) AS income_band_sk,
    COALESCE(sa.ib_lower_bound, wa.ib_lower_bound)   AS lower_bound,
    COALESCE(sa.ib_upper_bound, wa.ib_upper_bound)   AS upper_bound,
    COALESCE(sa.hd_buy_potential, wa.hd_buy_potential) AS buy_potential,
    COALESCE(sa.store_net_loss, 0) AS store_net_loss,
    COALESCE(wa.web_net_loss, 0)   AS web_net_loss,
    COALESCE(sa.store_return_amt, 0) AS store_return_amt,
    COALESCE(wa.web_return_amt, 0)   AS web_return_amt,
    COALESCE(sa.store_return_cnt, 0) AS store_return_cnt,
    COALESCE(wa.web_return_cnt, 0)   AS web_return_cnt,
    (COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) AS total_net_loss,
    (COALESCE(sa.store_return_amt, 0) + COALESCE(wa.web_return_amt, 0)) AS total_return_amt,
    (COALESCE(sa.store_return_cnt, 0) + COALESCE(wa.web_return_cnt, 0)) AS total_return_cnt
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.ib_income_band_sk = wa.ib_income_band_sk
   AND sa.hd_buy_potential = wa.hd_buy_potential
ORDER BY total_net_loss DESC
LIMIT 20
