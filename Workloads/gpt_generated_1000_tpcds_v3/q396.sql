WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_hdemo_sk AS hd_demo_sk,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
    GROUP BY
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_hdemo_sk
),
cr_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        cr.cr_refunded_hdemo_sk AS hd_demo_sk,
        cr.cr_reason_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_return_quantity > 0
    GROUP BY
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_reason_sk
),
sr_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_hdemo_sk AS hd_demo_sk,
        sr.sr_reason_sk,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(sr.sr_return_quantity) AS total_store_return_qty,
        COUNT(*) AS store_return_cnt
    FROM tpcds.store_returns sr
    GROUP BY
        sr.sr_item_sk,
        sr.sr_hdemo_sk,
        sr.sr_reason_sk
),
union_agg AS (
    SELECT
        cs_agg.cs_item_sk AS item_sk,
        cs_agg.cs_call_center_sk AS cc_sk,
        cs_agg.cs_warehouse_sk AS wh_sk,
        cs_agg.cs_ship_mode_sk AS sm_sk,
        cs_agg.hd_demo_sk,
        NULL AS reason_sk,
        cs_agg.total_sales,
        cs_agg.total_quantity,
        cs_agg.order_cnt,
        NULL AS total_return_amount,
        NULL AS total_return_qty,
        NULL AS return_cnt,
        NULL AS total_store_return_amt,
        NULL AS total_store_return_qty,
        NULL AS store_return_cnt
    FROM cs_agg

    UNION ALL

    SELECT
        cr_agg.cr_item_sk AS item_sk,
        cr_agg.cr_call_center_sk AS cc_sk,
        cr_agg.cr_warehouse_sk AS wh_sk,
        cr_agg.cr_ship_mode_sk AS sm_sk,
        cr_agg.hd_demo_sk,
        cr_agg.cr_reason_sk AS reason_sk,
        NULL AS total_sales,
        NULL AS total_quantity,
        NULL AS order_cnt,
        cr_agg.total_return_amount,
        cr_agg.total_return_qty,
        cr_agg.return_cnt,
        NULL AS total_store_return_amt,
        NULL AS total_store_return_qty,
        NULL AS store_return_cnt
    FROM cr_agg

    UNION ALL

    SELECT
        sr_agg.sr_item_sk AS item_sk,
        NULL AS cc_sk,
        NULL AS wh_sk,
        NULL AS sm_sk,
        sr_agg.hd_demo_sk,
        sr_agg.sr_reason_sk AS reason_sk,
        NULL AS total_sales,
        NULL AS total_quantity,
        NULL AS order_cnt,
        NULL AS total_return_amount,
        NULL AS total_return_qty,
        NULL AS return_cnt,
        sr_agg.total_store_return_amt,
        sr_agg.total_store_return_qty,
        sr_agg.store_return_cnt
    FROM sr_agg
)
SELECT
    i.i_item_id,
    i.i_category,
    i.i_class_id,
    cc.cc_name,
    w.w_warehouse_name,
    sm.sm_type,
    r.r_reason_desc,
    SUM(ua.total_sales) AS sum_sales,
    SUM(ua.total_return_amount) AS sum_return_amount,
    SUM(ua.total_store_return_amt) AS sum_store_return_amt,
    COUNT(*) AS row_cnt
FROM union_agg ua
LEFT JOIN tpcds.item i
    ON ua.item_sk = i.i_item_sk
LEFT JOIN tpcds.call_center cc
    ON ua.cc_sk = cc.cc_call_center_sk
LEFT JOIN tpcds.warehouse w
    ON ua.wh_sk = w.w_warehouse_sk
LEFT JOIN tpcds.ship_mode sm
    ON ua.sm_sk = sm.sm_ship_mode_sk
LEFT JOIN tpcds.reason r
    ON ua.reason_sk = r.r_reason_sk
LEFT JOIN tpcds.household_demographics hd
    ON ua.hd_demo_sk = hd.hd_demo_sk
WHERE i.i_class_id = 10
  AND r.r_reason_desc LIKE '%color%'
  AND cc.cc_state = 'CA'
GROUP BY
    i.i_item_id,
    i.i_category,
    i.i_class_id,
    cc.cc_name,
    w.w_warehouse_name,
    sm.sm_type,
    r.r_reason_desc
HAVING SUM(ua.total_sales) > 10000
   AND COUNT(*) > 1
ORDER BY sum_sales DESC
LIMIT 100
