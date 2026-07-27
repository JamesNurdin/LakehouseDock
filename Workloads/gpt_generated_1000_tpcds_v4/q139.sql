WITH
    ss AS (
        SELECT *
        FROM store_sales
    ),
    d_sales AS (
        SELECT *
        FROM date_dim
    )
SELECT
    d_year,
    p_promo_name,
    ib_lower_bound,
    ib_upper_bound,
    SUM(ss_net_profit)          AS total_store_profit,
    SUM(cr_net_loss)            AS total_catalog_return_loss,
    SUM(wr_net_loss)            AS total_web_return_loss
FROM (
    SELECT
        d_sales.d_year,
        p.p_promo_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_net_profit,
        cr.cr_net_loss,
        wr.wr_net_loss
    FROM ss
    JOIN d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN household_demographics hd_bill ON ss.ss_hdemo_sk = hd_bill.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end   ON p.p_end_date_sk   = d_promo_end.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sales.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN date_dim d_ship_date ON ws.ws_ship_date_sk = d_ship_date.d_date_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
    JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
) AS joined
GROUP BY
    d_year,
    p_promo_name,
    ib_lower_bound,
    ib_upper_bound
ORDER BY
    d_year,
    p_promo_name
LIMIT 100
