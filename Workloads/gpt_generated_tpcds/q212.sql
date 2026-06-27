WITH ws_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS ws_order_cnt,
        SUM(ws.ws_net_paid) AS total_ws_net_paid,
        SUM(ws.ws_net_profit) AS total_ws_net_profit
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
),
cr_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_buy_potential,
        COUNT(DISTINCT cr.cr_order_number) AS cr_order_cnt,
        SUM(cr.cr_return_amount) AS total_cr_return_amount,
        SUM(cr.cr_net_loss) AS total_cr_net_loss
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, hd.hd_buy_potential
)
SELECT
    COALESCE(ws.ib_lower_bound, cr.ib_lower_bound) AS lower_bound,
    COALESCE(ws.ib_upper_bound, cr.ib_upper_bound) AS upper_bound,
    COALESCE(ws.hd_buy_potential, cr.hd_buy_potential) AS buy_potential,
    COALESCE(ws.ws_order_cnt, 0) AS ws_order_cnt,
    COALESCE(ws.total_ws_net_paid, 0) AS total_ws_net_paid,
    COALESCE(ws.total_ws_net_profit, 0) AS total_ws_net_profit,
    COALESCE(cr.cr_order_cnt, 0) AS cr_order_cnt,
    COALESCE(cr.total_cr_return_amount, 0) AS total_cr_return_amount,
    COALESCE(cr.total_cr_net_loss, 0) AS total_cr_net_loss,
    COALESCE(ws.total_ws_net_profit, 0) - COALESCE(cr.total_cr_net_loss, 0) AS net_profit_after_returns
FROM ws_agg ws
FULL OUTER JOIN cr_agg cr
    ON ws.ib_income_band_sk = cr.ib_income_band_sk
    AND ws.hd_buy_potential = cr.hd_buy_potential
ORDER BY lower_bound, buy_potential
