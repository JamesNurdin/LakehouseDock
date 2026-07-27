-- goal: Analyze combined catalog and store return performance by call center, website, and year, including inventory and income‑band demographics, with aggregated measures and a ranking window.
WITH base AS (
    SELECT
        cc.cc_name,
        ws.web_name,
        dp.d_year,
        cr.cr_order_number,
        cr.cr_return_amount,
        sr.sr_return_amt,
        inv.inv_quantity_on_hand,
        income.ib_lower_bound,
        income.ib_upper_bound,
        cd_ref.cd_education_status,
        cd_ref.cd_dep_count,
        cc.cc_state
    FROM
        call_center cc
        JOIN catalog_returns cr
            ON cc.cc_call_center_sk = cr.cr_call_center_sk
        JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN date_dim dp
            ON cr.cr_returned_date_sk = dp.d_date_sk
        JOIN time_dim tm
            ON cr.cr_returned_time_sk = tm.t_time_sk
        JOIN customer c_ref
            ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
        JOIN customer_demographics cd_ref
            ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        JOIN household_demographics hd_ref
            ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
        JOIN customer_address ca_ref
            ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
        JOIN customer c_ret
            ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
        JOIN customer_demographics cd_ret
            ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
        JOIN household_demographics hd_ret
            ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
        JOIN customer_address ca_ret
            ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
        JOIN store_returns sr
            ON sr.sr_returned_date_sk = dp.d_date_sk
        JOIN time_dim tm2
            ON sr.sr_return_time_sk = tm2.t_time_sk
        JOIN customer c_sr
            ON sr.sr_customer_sk = c_sr.c_customer_sk
        JOIN customer_demographics cd_sr
            ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
        JOIN household_demographics hd_sr
            ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
        JOIN customer_address ca_sr
            ON sr.sr_addr_sk = ca_sr.ca_address_sk
        JOIN inventory inv
            ON inv.inv_date_sk = dp.d_date_sk
        JOIN income_band income
            ON hd_ref.hd_income_band_sk = income.ib_income_band_sk
        JOIN web_site ws
            ON ws.web_open_date_sk = dp.d_date_sk
        JOIN web_page wp
            ON wp.wp_creation_date_sk = dp.d_date_sk
            AND wp.wp_customer_sk = c_sr.c_customer_sk
    WHERE
        dp.d_year = 2001
        AND cd_ref.cd_education_status = 'Advanced Degree'
        AND cd_ref.cd_dep_count >= 2
        AND income.ib_lower_bound >= 30000
        AND inv.inv_quantity_on_hand > 0
        AND cc.cc_state = 'CA'
)
SELECT
    cc_name,
    web_name,
    d_year,
    COUNT(DISTINCT cr_order_number) AS total_catalog_orders,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(sr_return_amt) AS total_store_return_amount,
    AVG(inv_quantity_on_hand) AS avg_inventory_quantity,
    MIN(ib_lower_bound) AS min_income_lower,
    MAX(ib_upper_bound) AS max_income_upper,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY SUM(cr_return_amount) DESC) AS rn
FROM base
GROUP BY
    cc_name,
    web_name,
    d_year
ORDER BY
    total_catalog_return_amount DESC
LIMIT 100
