WITH store_agg AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        s.s_store_id,
        s.s_state,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(*) AS store_txn_count
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE
        s.s_number_employees > 200
        AND i.i_current_price BETWEEN 10 AND 1000
        AND s.s_state = 'CA'
        AND cd.cd_gender = 'M'
        AND ss.ss_ext_sales_price > 500
    GROUP BY i.i_item_id, i.i_brand, s.s_store_id, s.s_state
),
catalog_agg AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        cc.cc_call_center_id,
        cp.cp_department,
        sm.sm_type,
        w.w_state,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(cs.cs_quantity) AS catalog_quantity,
        COUNT(*) AS catalog_txn_count
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE
        cc.cc_state = 'CA'
        AND w.w_state = 'CA'
        AND cp.cp_department = 'Electronics'
        AND sm.sm_type = 'AIR'
        AND cs.cs_ext_sales_price > 1000
    GROUP BY i.i_item_id, i.i_brand, cc.cc_call_center_id, cp.cp_department, sm.sm_type, w.w_state
)
SELECT
    sa.i_item_id,
    sa.i_brand,
    sa.s_store_id,
    sa.s_state AS store_state,
    ca.cc_call_center_id,
    ca.w_state AS warehouse_state,
    sa.store_sales_amount,
    ca.catalog_sales_amount,
    (sa.store_sales_amount + ca.catalog_sales_amount) AS total_sales_amount,
    (sa.store_profit + ca.catalog_profit) AS total_profit,
    CASE
        WHEN (sa.store_profit + ca.catalog_profit) > 10000 THEN 'High'
        WHEN (sa.store_profit + ca.catalog_profit) BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    (
        SELECT AVG(cs.cs_ext_discount_amt)
        FROM catalog_sales cs
        JOIN item i2 ON cs.cs_item_sk = i2.i_item_sk
        WHERE i2.i_brand = sa.i_brand
    ) AS avg_brand_discount
FROM store_agg sa
JOIN catalog_agg ca ON sa.i_item_id = ca.i_item_id AND sa.i_brand = ca.i_brand
WHERE
    (sa.store_sales_amount + ca.catalog_sales_amount) > 5000
    AND (sa.store_profit + ca.catalog_profit) > 1000
    AND EXISTS (
        SELECT 1
        FROM warehouse w2
        WHERE w2.w_state = ca.w_state
          AND w2.w_gmt_offset > 0
    )
ORDER BY total_sales_amount DESC
LIMIT 100
