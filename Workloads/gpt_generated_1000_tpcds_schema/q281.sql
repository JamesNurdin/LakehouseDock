WITH joined_all AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_state,
        d.d_year,
        ib.ib_income_band_sk,
        ib.ib_upper_bound,
        r.r_reason_desc,
        ss.ss_net_paid AS store_net_paid,
        ss.ss_net_profit AS store_net_profit,
        ws.ws_net_paid AS web_net_paid,
        ws.ws_net_profit AS web_net_profit,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS return_loss
    FROM store_sales ss
    JOIN catalog_returns cr
        ON ss.ss_sold_date_sk = cr.cr_returned_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = ss.ss_sold_date_sk
    JOIN date_dim d
        ON d.d_date_sk = ss.ss_sold_date_sk
    JOIN customer c
        ON c.c_customer_sk = ss.ss_customer_sk
    JOIN customer_demographics cd
        ON cd.cd_demo_sk = ss.ss_cdemo_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = ss.ss_hdemo_sk
    JOIN income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN reason r
        ON r.r_reason_sk = cr.cr_reason_sk
    JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND cc.cc_state = 'CA'
      AND ib.ib_upper_bound <= 120000
      AND r.r_reason_desc = 'Customer Not Satisfied'
      AND cd.cd_gender = 'M'
),
agg_store AS (
    SELECT
        cc_call_center_id,
        d_year,
        ib_income_band_sk,
        SUM(store_net_paid) AS total_paid,
        SUM(store_net_profit) AS total_profit,
        SUM(return_amount) AS total_return_amount,
        SUM(return_loss) AS total_return_loss
    FROM joined_all
    GROUP BY cc_call_center_id, d_year, ib_income_band_sk
),
agg_web AS (
    SELECT
        cc_call_center_id,
        d_year,
        ib_income_band_sk,
        SUM(web_net_paid) AS total_paid,
        SUM(web_net_profit) AS total_profit,
        SUM(return_amount) AS total_return_amount,
        SUM(return_loss) AS total_return_loss
    FROM joined_all
    GROUP BY cc_call_center_id, d_year, ib_income_band_sk
),
union_agg AS (
    SELECT cc_call_center_id, d_year, ib_income_band_sk,
           total_paid, total_profit,
           total_return_amount, total_return_loss
    FROM agg_store
    UNION DISTINCT
    SELECT cc_call_center_id, d_year, ib_income_band_sk,
           total_paid, total_profit,
           total_return_amount, total_return_loss
    FROM agg_web
)
SELECT
    cc_call_center_id,
    d_year,
    ib_income_band_sk,
    SUM(total_paid) AS sum_total_paid,
    SUM(total_profit) AS sum_total_profit,
    SUM(total_return_amount) AS sum_total_return_amount,
    SUM(total_return_loss) AS sum_total_return_loss
FROM union_agg
GROUP BY ROLLUP (cc_call_center_id, d_year, ib_income_band_sk)
ORDER BY cc_call_center_id, d_year, ib_income_band_sk
