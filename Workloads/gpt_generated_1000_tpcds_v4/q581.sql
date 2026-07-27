WITH rc AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_customer_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 0
)
SELECT
    cc.cc_name AS call_center_name,
    dc.d_year,
    sm.sm_carrier,
    st.s_city,
    SUM(rc.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT rc.cr_order_number) AS distinct_orders,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(rc.cr_return_quantity) AS min_quantity,
    MAX(rc.cr_return_quantity) AS max_quantity
FROM rc
JOIN date_dim dc
    ON rc.cr_returned_date_sk = dc.d_date_sk
JOIN time_dim td
    ON rc.cr_returned_time_sk = td.t_time_sk
JOIN item i
    ON rc.cr_item_sk = i.i_item_sk
JOIN customer c_ref
    ON rc.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer_demographics cd_ref
    ON rc.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer c_ret
    ON rc.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer_demographics cd_ret
    ON rc.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN call_center cc
    ON rc.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON rc.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON rc.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store st
    ON st.s_closed_date_sk = dc.d_date_sk
WHERE
    i.i_wholesale_cost BETWEEN 5 AND 15
    AND sm.sm_carrier = 'FEDEX'
    AND cc.cc_state = 'CA'
    AND dc.d_year = 2002
    AND st.s_city = 'Seattle'
    AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_returned_date_sk = rc.cr_returned_date_sk
          AND sr.sr_item_sk = rc.cr_item_sk
    )
    AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_returned_date_sk = rc.cr_returned_date_sk
          AND wr.wr_item_sk = rc.cr_item_sk
    )
GROUP BY
    cc.cc_name,
    dc.d_year,
    sm.sm_carrier,
    st.s_city
ORDER BY total_return_amount DESC
LIMIT 100
