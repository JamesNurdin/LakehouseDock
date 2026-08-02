WITH sales AS (
    SELECT
        w.w_warehouse_id,
        sm.sm_ship_mode_id,
        token AS description_word,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        CAST(NULL AS decimal(7,2)) AS total_returns,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        CAST(NULL AS integer) AS distinct_return_orders,
        'sales' AS activity_type
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN UNNEST(split(cp.cp_description, ' ')) AS t(token)
    WHERE cs.cs_sold_date_sk BETWEEN 2451910 AND 2451915
      AND hd.hd_income_band_sk IS NOT NULL
    GROUP BY ROLLUP (w.w_warehouse_id, sm.sm_ship_mode_id, token)
),
returns AS (
    SELECT
        w.w_warehouse_id,
        sm.sm_ship_mode_id,
        token AS description_word,
        CAST(NULL AS decimal(7,2)) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        CAST(NULL AS integer) AS distinct_orders,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
        'returns' AS activity_type
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN UNNEST(split(cp.cp_description, ' ')) AS t(token)
    WHERE cr.cr_returned_date_sk BETWEEN 2451910 AND 2451915
      AND hd.hd_vehicle_count > 0
    GROUP BY CUBE (w.w_warehouse_id, sm.sm_ship_mode_id, token)
)
SELECT DISTINCT
    activity_type,
    w_warehouse_id,
    sm_ship_mode_id,
    description_word,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_returns, 0) AS total_returns,
    COALESCE(distinct_orders, 0) AS distinct_orders,
    COALESCE(distinct_return_orders, 0) AS distinct_return_orders,
    ROW_NUMBER() OVER (
        PARTITION BY activity_type
        ORDER BY (COALESCE(total_sales, 0) + COALESCE(total_returns, 0)) DESC
    ) AS activity_rank
FROM (
    SELECT
        w_warehouse_id,
        sm_ship_mode_id,
        description_word,
        total_sales,
        total_returns,
        distinct_orders,
        distinct_return_orders,
        activity_type
    FROM sales
    UNION ALL
    SELECT
        w_warehouse_id,
        sm_ship_mode_id,
        description_word,
        total_sales,
        total_returns,
        distinct_orders,
        distinct_return_orders,
        activity_type
    FROM returns
) combined
ORDER BY activity_type, activity_rank
LIMIT 100
