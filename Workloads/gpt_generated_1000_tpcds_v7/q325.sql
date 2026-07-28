WITH returns_enriched AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cs.cs_order_number,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        i.i_item_desc,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        cc.cc_zip,
        w.w_city AS w_city,
        w.w_street_name,
        w.w_suite_number,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
)
SELECT
    cc_name,
    CONCAT(cc_city, ', ', cc_state) AS cc_location,
    SUBSTRING(cc_zip, 1, 5) AS zip_prefix,
    w_city AS warehouse_city,
    REGEXP_EXTRACT(i_item_desc, '^(\\w+)', 1) AS item_category_prefix,
    COUNT(*) AS returns_cnt,
    SUM(cr_net_loss) AS total_net_loss
FROM returns_enriched
WHERE REGEXP_LIKE(cc_name, 'Center')
  AND w_street_name LIKE '%Ave%'
  AND r_reason_desc LIKE '%Defect%'
GROUP BY
    cc_name,
    CONCAT(cc_city, ', ', cc_state),
    SUBSTRING(cc_zip, 1, 5),
    w_city,
    REGEXP_EXTRACT(i_item_desc, '^(\\w+)', 1)
ORDER BY total_net_loss DESC
LIMIT 10
