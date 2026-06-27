-- Net profit after returns by store, month and household income band
WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        date_trunc('month', d.d_date) AS month_start,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(ss.ss_net_paid) AS total_sales_net_paid
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        date_trunc('month', d.d_date),
        ib.ib_lower_bound,
        ib.ib_upper_bound
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        date_trunc('month', d.d_date) AS month_start,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(sr.sr_net_loss) AS total_returns_net_loss
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        date_trunc('month', d.d_date),
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    sa.s_store_name,
    sa.month_start,
    sa.income_lower,
    sa.income_upper,
    sa.total_sales_net_paid,
    COALESCE(ra.total_returns_net_loss, 0) AS total_returns_net_loss,
    sa.total_sales_net_paid - COALESCE(ra.total_returns_net_loss, 0) AS net_profit_after_returns
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
    AND sa.month_start = ra.month_start
    AND sa.income_lower = ra.income_lower
    AND sa.income_upper = ra.income_upper
ORDER BY net_profit_after_returns DESC
LIMIT 100
