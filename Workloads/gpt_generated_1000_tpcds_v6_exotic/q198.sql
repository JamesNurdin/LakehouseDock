WITH sales_agg AS (
    SELECT
        cd.cd_gender AS cd_gender,
        cd.cd_marital_status AS cd_marital_status,
        p.p_promo_name AS p_promo_name,
        SUM(cs.cs_net_paid) AS total_sales,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_quantity) AS avg_qty,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM catalog_sales cs
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND cd.cd_education_status = 'Advanced Degree'
      AND hd.hd_income_band_sk = 15
      AND inv.inv_quantity_on_hand > 1000
    GROUP BY ROLLUP (cd.cd_gender, cd.cd_marital_status, p.p_promo_name)
),
web_sales_agg AS (
    SELECT
        cd.cd_gender AS cd_gender,
        cd.cd_marital_status AS cd_marital_status,
        p.p_promo_name AS p_promo_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(*) AS web_sales_cnt,
        AVG(ws.ws_quantity) AS avg_web_qty,
        CASE WHEN SUM(ws.ws_net_paid) > 80000 THEN 'HIGH' ELSE 'LOW' END AS web_sales_category
    FROM web_sales ws
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_quantity > 5
      AND cd.cd_education_status = 'Advanced Degree'
      AND hd.hd_income_band_sk = 15
    GROUP BY GROUPING SETS (
        (cd.cd_gender, cd.cd_marital_status, p.p_promo_name),
        (cd.cd_gender, cd.cd_marital_status),
        (cd.cd_gender),
        ()
    )
),
returns_agg AS (
    SELECT
        cd.cd_gender AS cd_gender,
        cd.cd_marital_status AS cd_marital_status,
        r.r_reason_desc AS r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_store_return_amount,
        CASE WHEN SUM(cr.cr_return_amount) > 50000 THEN 'HIGH' ELSE 'LOW' END AS return_category
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN store_returns sr ON sr.sr_reason_sk = r.r_reason_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_amount > 50
      AND cc.cc_state = 'CA'
    GROUP BY CUBE (cd.cd_gender, cd.cd_marital_status, r.r_reason_desc)
)
SELECT
    gender,
    marital_status,
    promo_name,
    reason_desc,
    total_sales,
    total_web_sales,
    total_return_amount,
    total_store_return_amount,
    sales_category,
    web_sales_category,
    return_category,
    SUM(COALESCE(total_sales,0) + COALESCE(total_web_sales,0) - COALESCE(total_return_amount,0) - COALESCE(total_store_return_amount,0))
        OVER (PARTITION BY gender ORDER BY COALESCE(total_sales,0) DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net,
    ROW_NUMBER() OVER (PARTITION BY gender ORDER BY COALESCE(total_sales,0) DESC) AS sales_rank
FROM (
    SELECT
        cd_gender AS gender,
        cd_marital_status AS marital_status,
        p_promo_name AS promo_name,
        NULL AS reason_desc,
        total_sales,
        NULL AS total_web_sales,
        NULL AS total_return_amount,
        NULL AS total_store_return_amount,
        sales_category,
        NULL AS web_sales_category,
        NULL AS return_category
    FROM sales_agg
    UNION ALL
    SELECT
        cd_gender AS gender,
        cd_marital_status AS marital_status,
        p_promo_name AS promo_name,
        NULL AS reason_desc,
        NULL AS total_sales,
        total_web_sales,
        NULL AS total_return_amount,
        NULL AS total_store_return_amount,
        NULL AS sales_category,
        web_sales_category,
        NULL AS return_category
    FROM web_sales_agg
    UNION ALL
    SELECT
        cd_gender AS gender,
        cd_marital_status AS marital_status,
        NULL AS promo_name,
        r_reason_desc AS reason_desc,
        NULL AS total_sales,
        NULL AS total_web_sales,
        total_return_amount,
        total_store_return_amount,
        NULL AS sales_category,
        NULL AS web_sales_category,
        return_category
    FROM returns_agg
) u
ORDER BY gender, cumulative_net DESC
LIMIT 100
