-- Goal: Analyze net loss and profit for catalog returns, store returns, and web sales by customer income band and promotion, showing the number of distinct customers, loss indicator, and average store paid for each promotion.
WITH joined_data AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_ticket_number,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        cr.cr_net_loss,
        sr.sr_net_loss,
        ws.ws_net_profit,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        promo.p_promo_name,
        promo.p_promo_sk,
        sm_cr.sm_ship_mode_id      AS cr_ship_mode_id,
        sm_ws.sm_ship_mode_id      AS ws_ship_mode_id
    FROM store_sales ss
    JOIN date_dim dd_ss
        ON ss.ss_sold_date_sk = dd_ss.d_date_sk
    JOIN customer cust
        ON ss.ss_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion promo
        ON ss.ss_promo_sk = promo.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = cust.c_customer_sk
        AND cr.cr_returned_date_sk = dd_ss.d_date_sk
    LEFT JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = cust.c_customer_sk
        AND ws.ws_sold_date_sk = dd_ss.d_date_sk
    LEFT JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    p_promo_name,
    COUNT(DISTINCT ss_customer_sk)                                AS num_customers,
    SUM(COALESCE(cr_net_loss, 0))                                AS catalog_net_loss,
    SUM(COALESCE(sr_net_loss, 0))                                AS store_net_loss,
    SUM(COALESCE(ws_net_profit, 0))                              AS web_net_profit,
    CASE WHEN SUM(COALESCE(cr_net_loss, 0)) > 0 THEN 'Loss' ELSE 'Gain' END AS catalog_loss_indicator,
    (
        SELECT AVG(ss2.ss_net_paid)
        FROM store_sales ss2
        WHERE ss2.ss_promo_sk = joined_data.p_promo_sk
    )                                                            AS avg_store_paid_for_promo
FROM joined_data
GROUP BY
    ib_lower_bound,
    ib_upper_bound,
    p_promo_name,
    p_promo_sk
ORDER BY catalog_net_loss DESC
LIMIT 100
