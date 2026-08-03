WITH item_attrs AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_item_desc,
        i_brand,
        i_color,
        i_size,
        ARRAY[i_color, i_size] AS attr_array
    FROM tpcds.item
),
expanded_item AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_item_desc,
        i_brand,
        attr
    FROM item_attrs
    CROSS JOIN UNNEST(attr_array) AS t(attr)
)
SELECT
    cp.cp_department,
    r.r_reason_desc,
    td.t_sub_shift,
    cd.cd_marital_status,
    SUM(cs.cs_net_paid) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    AVG(CASE WHEN cr.cr_return_amount > 0 THEN cr.cr_return_amount ELSE NULL END) AS avg_return_amount,
    MIN(ws.ws_net_paid) AS min_web_paid,
    MAX(sr.sr_return_amt) AS max_store_return_amt
FROM tpcds.catalog_sales cs
JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN expanded_item ei
    ON cs.cs_item_sk = ei.i_item_sk
JOIN tpcds.time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN tpcds.customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
JOIN tpcds.reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = ei.i_item_sk
    AND sr.sr_return_time_sk = td.t_time_sk
JOIN tpcds.web_sales ws
    ON ws.ws_item_sk = ei.i_item_sk
JOIN tpcds.web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
WHERE
    cp.cp_department = 'Electronics'
    AND r.r_reason_desc = 'Did not fit'
    AND td.t_time = 13
    AND cd.cd_marital_status = 'M'
GROUP BY
    cp.cp_department,
    r.r_reason_desc,
    td.t_sub_shift,
    cd.cd_marital_status
ORDER BY total_sales DESC
LIMIT 100
