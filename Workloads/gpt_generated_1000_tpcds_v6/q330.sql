WITH base AS (
    SELECT
        cc.cc_state,
        cp.cp_department,
        ib.ib_income_band_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_order_number,
        sr.sr_return_amt,
        sr.sr_ticket_number
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_state = 'CA'
      AND ib.ib_upper_bound >= 100000
      AND cr.cr_return_tax > 10.0
      AND sr.sr_return_amt > 50.0
)
SELECT
    cc_state,
    cp_department,
    ib_income_band_sk,
    SUM(cr_return_amount)      AS total_catalog_return_amount,
    SUM(sr_return_amt)         AS total_store_return_amount,
    COUNT(DISTINCT cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr_ticket_number) AS store_tickets,
    AVG(cr_return_tax)         AS avg_catalog_return_tax
FROM base
GROUP BY GROUPING SETS (
    (cc_state, cp_department, ib_income_band_sk),
    (cc_state, cp_department),
    (cc_state, ib_income_band_sk),
    (cp_department, ib_income_band_sk),
    (cc_state),
    (cp_department),
    (ib_income_band_sk),
    ()
)
ORDER BY total_catalog_return_amount DESC
LIMIT 100
