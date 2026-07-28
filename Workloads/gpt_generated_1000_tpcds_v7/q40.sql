WITH sales_data AS (
    SELECT
        cc.cc_call_center_id,
        cp.cp_department,
        sm.sm_carrier,
        i.i_item_id,
        cs.cs_order_number,
        cs.cs_ext_sales_price AS ext_sales_price,
        0.0 AS return_amount,
        cs.cs_quantity AS cs_quantity,
        i.i_current_price,
        inv.inv_quantity_on_hand,
        CASE WHEN cs.cs_quantity > 5 THEN 'BULK' ELSE 'SMALL' END AS qty_category
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE cs.cs_quantity > 0
      AND i.i_current_price BETWEEN 10 AND 1000
      AND inv.inv_quantity_on_hand > 0
      AND cc.cc_state = 'CA'
      AND sm.sm_carrier = 'FEDEX'
      AND cc.cc_rec_start_date <= DATE '2000-01-01'
),
returns_data AS (
    SELECT
        cc.cc_call_center_id,
        cp.cp_department,
        sm.sm_carrier,
        i.i_item_id,
        cr.cr_order_number AS cs_order_number,
        0.0 AS ext_sales_price,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS cs_quantity,
        i.i_current_price,
        inv.inv_quantity_on_hand,
        CASE WHEN cr.cr_return_quantity > 20 THEN 'HIGH' ELSE 'LOW' END AS qty_category
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE cr.cr_return_quantity > 10
      AND cr.cr_return_amount > 0
      AND i.i_current_price BETWEEN 10 AND 1000
      AND inv.inv_quantity_on_hand > 0
      AND cc.cc_state = 'CA'
      AND sm.sm_carrier = 'FEDEX'
      AND cc.cc_rec_end_date >= DATE '1995-01-01'
),
combined AS (
    SELECT * FROM sales_data
    UNION ALL
    SELECT * FROM returns_data
),
agg_rollup AS (
    SELECT
        cd.cc_call_center_id,
        cd.cp_department,
        cd.sm_carrier,
        SUM(cd.ext_sales_price) AS total_sales,
        SUM(cd.return_amount) AS total_returns,
        SUM(cd.cs_quantity) AS total_quantity,
        CASE
            WHEN SUM(cd.ext_sales_price) > 10000 THEN 'BIG'
            ELSE 'SMALL'
        END AS sales_size_category
    FROM combined cd
    GROUP BY ROLLUP (cd.cc_call_center_id, cd.cp_department, cd.sm_carrier)
)
SELECT
    ar.cc_call_center_id,
    ar.cp_department,
    ar.sm_carrier,
    ar.total_sales,
    ar.total_returns,
    ar.total_quantity,
    ar.sales_size_category,
    ROW_NUMBER() OVER (PARTITION BY ar.cc_call_center_id ORDER BY ar.total_sales DESC) AS sales_rank,
    (SELECT MAX(total_sales) FROM agg_rollup) AS max_total_sales_overall
FROM agg_rollup ar
JOIN call_center cc ON ar.cc_call_center_id = cc.cc_call_center_id
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_call_center_sk = cc.cc_call_center_sk
      AND cr.cr_net_loss > 1000
)
ORDER BY ar.total_sales DESC
LIMIT 100
