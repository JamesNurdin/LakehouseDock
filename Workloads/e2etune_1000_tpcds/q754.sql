WITH cr_agg AS (
    SELECT
        cr.cr_warehouse_sk AS warehouse_sk,
        hd.hd_income_band_sk,
        sm.sm_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_return_tax > 0
    GROUP BY cr.cr_warehouse_sk, hd.hd_income_band_sk, sm.sm_type
),
ss_agg AS (
    SELECT
        ss.ss_hdemo_sk,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_paid) AS total_sales_net_paid,
        SUM(ss.ss_net_profit) AS total_sales_net_profit
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY ss.ss_hdemo_sk, hd.hd_income_band_sk
)
SELECT
    w.w_warehouse_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cr_agg.sm_type,
    cr_agg.total_return_amount,
    cr_agg.total_net_loss,
    cr_agg.return_cnt,
    ss_agg.total_sales_net_paid,
    ss_agg.total_sales_net_profit,
    cr_agg.total_return_amount / NULLIF(ss_agg.total_sales_net_paid, 0) AS return_to_sales_ratio,
    RANK() OVER (ORDER BY cr_agg.total_net_loss DESC) AS loss_rank
FROM cr_agg
JOIN ss_agg
    ON cr_agg.hd_income_band_sk = ss_agg.hd_income_band_sk
JOIN warehouse w
    ON cr_agg.warehouse_sk = w.w_warehouse_sk
JOIN income_band ib
    ON cr_agg.hd_income_band_sk = ib.ib_income_band_sk
WHERE cr_agg.return_cnt > 10
ORDER BY cr_agg.total_net_loss DESC
LIMIT 5
