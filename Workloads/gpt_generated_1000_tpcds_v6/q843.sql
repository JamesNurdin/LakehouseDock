WITH cs_agg AS (
    SELECT
        cc.cc_call_center_id,
        cs.cs_call_center_sk AS call_center_sk,
        cp.cp_catalog_number,
        sm.sm_carrier,
        w.w_warehouse_name,
        t_sold.t_hour,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt,
        -- additional aliases for extra joins
        cc2.cc_call_center_id AS cc2_id,
        cp2.cp_catalog_number AS cp2_number
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    -- repeated joins using aliases to increase join count
    JOIN call_center cc2
        ON cs.cs_call_center_sk = cc2.cc_call_center_sk
    JOIN catalog_page cp2
        ON cs.cs_catalog_page_sk = cp2.cp_catalog_page_sk
    GROUP BY
        cc.cc_call_center_id,
        cs.cs_call_center_sk,
        cp.cp_catalog_number,
        sm.sm_carrier,
        w.w_warehouse_name,
        t_sold.t_hour,
        cc2.cc_call_center_id,
        cp2.cp_catalog_number
)
SELECT * FROM (
    -- First sub‑query: catalog side, filtered with a semi‑join on store_sales
    SELECT
        'catalog' AS source,
        ca.cc_call_center_id,
        ca.cp_catalog_number,
        ca.sm_carrier,
        ca.w_warehouse_name,
        ca.t_hour,
        ca.total_net_paid,
        ca.order_cnt
    FROM cs_agg ca
    WHERE EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_customer_sk = ca.call_center_sk
    )

    UNION ALL

    -- Second sub‑query: store side, using multiple joins to time_dim (different aliases)
    SELECT
        'store' AS source,
        NULL AS cc_call_center_id,
        NULL AS cp_catalog_number,
        'UNKNOWN' AS sm_carrier,
        NULL AS w_warehouse_name,
        t1.t_hour,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM store_sales ss
    JOIN time_dim t1
        ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN time_dim t2
        ON ss.ss_sold_time_sk = t2.t_time_sk
    GROUP BY t1.t_hour
) AS final_result
LIMIT 100
