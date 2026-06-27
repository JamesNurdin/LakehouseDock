WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        t.t_hour AS hour_of_day,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
      AND ib.ib_lower_bound >= 50000
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        t.t_hour,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        t.t_hour AS hour_of_day,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_net_loss) AS total_returns_loss
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
      AND ib.ib_lower_bound >= 50000
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        t.t_hour,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    COALESCE(sa.s_store_name, ra.s_store_name) AS store_name,
    COALESCE(sa.hour_of_day, ra.hour_of_day) AS hour_of_day,
    COALESCE(sa.ib_income_band_sk, ra.ib_income_band_sk) AS income_band_id,
    COALESCE(sa.ib_lower_bound, ra.ib_lower_bound) AS income_lower_bound,
    COALESCE(sa.ib_upper_bound, ra.ib_upper_bound) AS income_upper_bound,
    COALESCE(sa.total_sales_profit, 0) - COALESCE(ra.total_returns_loss, 0) AS net_profit
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
   AND sa.hour_of_day = ra.hour_of_day
   AND sa.ib_income_band_sk = ra.ib_income_band_sk
ORDER BY net_profit DESC
LIMIT 100
