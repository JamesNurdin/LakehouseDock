WITH
catalog AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_ship_mode_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_returning_addr_sk
    FROM catalog_returns cr
),
web AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_refunded_cdemo_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_returning_cdemo_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_returning_addr_sk
    FROM web_returns wr
)
SELECT
    d_cr.d_year AS return_year,
    i.i_category,
    cd_ref.cd_gender,
    cd_ret.cd_education_status,
    sm.sm_type,
    p.p_promo_name,
    s.s_store_name,
    ws.web_name,
    SUM(c.cr_return_amount) AS total_catalog_return_amount,
    SUM(c.cr_net_loss) AS total_catalog_net_loss,
    SUM(w.wr_return_amt) AS total_web_return_amount,
    SUM(w.wr_net_loss) AS total_web_net_loss,
    COUNT(*) AS total_returns
FROM catalog c
JOIN date_dim d_cr ON c.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr ON c.cr_returned_time_sk = t_cr.t_time_sk
JOIN item i ON c.cr_item_sk = i.i_item_sk
JOIN ship_mode sm ON c.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca_ref ON c.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret ON c.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_demographics cd_ref ON c.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret ON c.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ref ON c.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret ON c.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN income_band ib_ref ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
JOIN income_band ib_ret ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_cr.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_cr.d_date_sk
JOIN web w ON w.wr_item_sk = i.i_item_sk
JOIN date_dim d_wr ON w.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr ON w.wr_returned_time_sk = t_wr.t_time_sk
JOIN customer_address ca_ref_wr ON w.wr_refunded_addr_sk = ca_ref_wr.ca_address_sk
JOIN customer_address ca_ret_wr ON w.wr_returning_addr_sk = ca_ret_wr.ca_address_sk
JOIN customer_demographics cd_ref_wr ON w.wr_refunded_cdemo_sk = cd_ref_wr.cd_demo_sk
JOIN customer_demographics cd_ret_wr ON w.wr_returning_cdemo_sk = cd_ret_wr.cd_demo_sk
JOIN household_demographics hd_ref_wr ON w.wr_refunded_hdemo_sk = hd_ref_wr.hd_demo_sk
JOIN household_demographics hd_ret_wr ON w.wr_returning_hdemo_sk = hd_ret_wr.hd_demo_sk
JOIN income_band ib_ref_wr ON hd_ref_wr.hd_income_band_sk = ib_ref_wr.ib_income_band_sk
JOIN income_band ib_ret_wr ON hd_ret_wr.hd_income_band_sk = ib_ret_wr.ib_income_band_sk
GROUP BY
    d_cr.d_year,
    i.i_category,
    cd_ref.cd_gender,
    cd_ret.cd_education_status,
    sm.sm_type,
    p.p_promo_name,
    s.s_store_name,
    ws.web_name
ORDER BY total_catalog_return_amount DESC
LIMIT 100
