WITH store_part AS (
    SELECT
        s.s_state AS state,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    JOIN store s                         ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t                       ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd_bill   ON ss.ss_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill  ON ss.ss_hdemo_sk = hd_bill.hd_demo_sk
    JOIN promotion p                     ON ss.ss_promo_sk = p.p_promo_sk
    WHERE EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ss.ss_promo_sk
          AND p2.p_discount_active = 'Y'
    )
    GROUP BY s.s_state, p.p_promo_name
),
catalog_part AS (
    SELECT
        cc.cc_state AS state,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        COUNT(*) AS txn_cnt
    FROM catalog_sales cs
    JOIN call_center cc                     ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim t                         ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p                        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd_bill      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill     ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_demographics cd_ship      ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship     ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN catalog_page cp                    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm                       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY cc.cc_state, p.p_promo_name
),
combined_sales AS (
    SELECT state, promo_name, total_sales, txn_cnt FROM store_part
    UNION ALL
    SELECT state, promo_name, total_sales, txn_cnt FROM catalog_part
)
SELECT
    state,
    promo_name,
    total_sales,
    txn_cnt
FROM combined_sales
ORDER BY total_sales DESC
LIMIT 100
