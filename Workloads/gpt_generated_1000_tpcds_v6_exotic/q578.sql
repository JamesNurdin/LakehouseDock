WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_date_sk BETWEEN 2450900 AND 2451100
    GROUP BY inv_item_sk, inv_warehouse_sk
),
distinct_reason AS (
    SELECT DISTINCT
        r_reason_sk,
        r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE 'Did not%'
)
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    cc.cc_state,
    cd.cd_education_status,
    dr.r_reason_desc,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    SUM(inv_agg.total_qty) AS total_inventory_qty
FROM catalog_returns cr
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN distinct_reason dr ON cr.cr_reason_sk = dr.r_reason_sk
JOIN inv_agg ON cr.cr_item_sk = inv_agg.inv_item_sk
            AND cr.cr_warehouse_sk = inv_agg.inv_warehouse_sk
WHERE
    cc.cc_state = 'CA'
    AND i.i_brand = 'BrandX'
    AND cd.cd_education_status = 'College'
    AND cc.cc_rec_start_date >= DATE '2000-01-01'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    cc.cc_state,
    cd.cd_education_status,
    dr.r_reason_desc
HAVING SUM(cr.cr_return_amount) > 1000
UNION ALL
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    NULL AS cc_state,
    cd.cd_education_status,
    dr.r_reason_desc,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    SUM(inv_agg.total_qty) AS total_inventory_qty
FROM web_returns wr
JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN distinct_reason dr ON wr.wr_reason_sk = dr.r_reason_sk
JOIN inv_agg ON wr.wr_item_sk = inv_agg.inv_item_sk
JOIN warehouse w ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    i.i_brand = 'BrandX'
    AND cd.cd_education_status = 'College'
    AND dr.r_reason_desc LIKE 'Did not%'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    cd.cd_education_status,
    dr.r_reason_desc
LIMIT 100
