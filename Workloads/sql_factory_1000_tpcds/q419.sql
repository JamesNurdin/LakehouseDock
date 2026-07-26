WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_category_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_category, i.i_category_id
),
item_agg AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_category_id,
        SUM(cs.cs_ext_sales_price) AS item_sales
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_category, i.i_category_id
),
item_rank AS (
    SELECT
        ia.i_item_sk,
        ia.i_category,
        ia.i_category_id,
        ia.item_sales,
        DENSE_RANK() OVER (PARTITION BY ia.i_category ORDER BY ia.item_sales DESC) AS sales_rank_in_category
    FROM item_agg ia
),
ship_mode_sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_ship_mode_sk,
        SUM(cs.cs_ext_sales_price) AS ship_mode_sales
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_ship_mode_sk
),
item_total_sales AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
),
ship_mode_share AS (
    SELECT
        sms.cs_item_sk,
        sm.sm_ship_mode_id,
        sms.ship_mode_sales,
        sms.ship_mode_sales * 100.0 / its.total_sales AS pct_of_item_sales
    FROM ship_mode_sales sms
    JOIN item_total_sales its ON its.cs_item_sk = sms.cs_item_sk
    JOIN ship_mode sm ON sms.cs_ship_mode_sk = sm.sm_ship_mode_sk
),
item_cc_sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        SUM(cs.cs_ext_sales_price) AS cc_sales
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_call_center_sk
),
item_call_center AS (
    SELECT
        ics.cs_item_sk,
        ics.cs_call_center_sk,
        ics.cc_sales,
        ROW_NUMBER() OVER (PARTITION BY ics.cs_item_sk ORDER BY ics.cc_sales DESC) AS rn
    FROM item_cc_sales ics
),
category_total AS (
    SELECT
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS category_total_sales
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category
)
SELECT
    ir.i_category,
    ir.i_category_id,
    ir.item_sales,
    ir.sales_rank_in_category,
    CASE
        WHEN ir.item_sales > 50000 THEN 'Top Seller'
        ELSE 'Regular'
    END AS sales_category,
    smc.sm_ship_mode_id AS ship_mode,
    ROUND(smc.pct_of_item_sales, 2) AS ship_mode_pct_of_item,
    cc.cc_call_center_id AS top_call_center,
    ROUND(ir.item_sales / ct.category_total_sales * 100, 2) AS item_sales_pct_of_category
FROM item_rank ir
JOIN item_sales isales
    ON isales.i_item_sk = ir.i_item_sk
LEFT JOIN ship_mode_share smc
    ON smc.cs_item_sk = ir.i_item_sk
LEFT JOIN item_call_center icc
    ON icc.cs_item_sk = ir.i_item_sk AND icc.rn = 1
LEFT JOIN call_center cc
    ON cc.cc_call_center_sk = icc.cs_call_center_sk
JOIN category_total ct
    ON ct.i_category = ir.i_category
ORDER BY ir.i_category, ir.sales_rank_in_category
