WITH sampled_cp AS (
    SELECT cp_catalog_page_sk, cp_catalog_number, cp_description
    FROM catalog_page TABLESAMPLE BERNOULLI (10)
),

distinct_reasons AS (
    SELECT DISTINCT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%defect%'
),

high_value_reasons AS (
    SELECT r.r_reason_sk
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 500
    INTERSECT
    SELECT r.r_reason_sk
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > 300
),

main AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        dr.r_reason_desc,
        cp.cp_catalog_number,
        sm.sm_type,
        w.w_state,
        cc.cc_state,
        t.t_hour,
        SUM(ss.ss_net_paid)                         AS total_sales,
        SUM(cr.cr_return_amount)                    AS total_catalog_returns,
        SUM(wr.wr_return_amt)                       AS total_web_returns,
        AVG(ss.ss_net_profit)                       AS avg_profit,
        COUNT(DISTINCT ss.ss_item_sk)               AS distinct_items_sold,
        CASE WHEN SUM(ss.ss_quantity) > 100 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM time_dim t
    FULL OUTER JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
    FULL OUTER JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
    FULL OUTER JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN sampled_cp cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN distinct_reasons dr ON (cr.cr_reason_sk = dr.r_reason_sk OR wr.wr_reason_sk = dr.r_reason_sk)
    WHERE
        cc.cc_state = 'CA'
        AND cp.cp_catalog_number IN (6, 10)
        AND sm.sm_type = 'AIR'
        AND w.w_state = 'TX'
        AND t.t_hour BETWEEN 9 AND 17
        AND s.s_gmt_offset = -8.00
        AND dr.r_reason_sk IN (SELECT r_reason_sk FROM high_value_reasons)
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        dr.r_reason_desc,
        cp.cp_catalog_number,
        sm.sm_type,
        w.w_state,
        cc.cc_state,
        t.t_hour
)
SELECT *
FROM main
ORDER BY total_sales DESC
LIMIT 100
