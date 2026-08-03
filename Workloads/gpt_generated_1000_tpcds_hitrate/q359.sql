WITH max_return_amt AS (
    SELECT MAX(cr_return_amount) AS max_amt
    FROM tpcds.catalog_returns
)
SELECT
    w.w_warehouse_name,
    cc.cc_name,
    i.i_brand,
    ib.ib_lower_bound,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year AS cc_open_year,
    hd_refunded.hd_vehicle_count AS refunded_vehicle_cnt,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS catalog_return_cnt,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    COUNT(sr.sr_ticket_number) AS store_return_cnt,
    CASE
        WHEN SUM(cr.cr_return_amount) > (SELECT max_amt FROM max_return_amt) THEN 'HIGH'
        ELSE 'NORMAL'
    END AS return_level,
    ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS rn
FROM tpcds.catalog_returns cr
JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN tpcds.household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN tpcds.date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN tpcds.date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN tpcds.date_dim d_c_shipto
    ON c_refunded.c_first_shipto_date_sk = d_c_shipto.d_date_sk
JOIN tpcds.ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.time_dim td
    ON cr.cr_returned_time_sk = td.t_time_sk
-- Store Returns and its related dimensions
JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN tpcds.date_dim d_sr_returned
    ON sr.sr_returned_date_sk = d_sr_returned.d_date_sk
JOIN tpcds.time_dim td_sr
    ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN tpcds.customer c_sr
    ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN tpcds.household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
WHERE EXISTS (
        SELECT 1
        FROM tpcds.catalog_returns cr2
        WHERE cr2.cr_item_sk = sr.sr_item_sk
          AND cr2.cr_returned_date_sk = sr.sr_returned_date_sk
    )
GROUP BY
    w.w_warehouse_name,
    cc.cc_name,
    i.i_brand,
    ib.ib_lower_bound,
    d_cc_closed.d_year,
    d_cc_open.d_year,
    hd_refunded.hd_vehicle_count,
    d_c_shipto.d_year
ORDER BY rn
LIMIT 100
