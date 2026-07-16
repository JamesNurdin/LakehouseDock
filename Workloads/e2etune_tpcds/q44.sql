WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        sm.sm_ship_mode_sk,
        sm.sm_type AS ship_mode_type,
        cp.cp_department,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_state = 'TN'
      AND cc.cc_class = 'large'
      AND cp.cp_department = 'Electronics'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY cc.cc_call_center_sk, cc.cc_name, sm.sm_ship_mode_sk, sm.sm_type, cp.cp_department
),
returns_agg AS (
    SELECT
        cr.cr_call_center_sk,
        sm.sm_ship_mode_sk,
        cp.cp_department,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_department = 'Electronics'
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY cr.cr_call_center_sk, sm.sm_ship_mode_sk, cp.cp_department
)
SELECT
    s.cc_name AS call_center_name,
    s.ship_mode_type,
    s.cp_department,
    s.total_net_profit,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    (s.total_net_profit - COALESCE(r.total_net_loss, 0)) AS net_revenue,
    s.total_discount / NULLIF(s.sales_cnt, 0) AS avg_discount_per_sale,
    RANK() OVER (PARTITION BY s.ship_mode_type ORDER BY (s.total_net_profit - COALESCE(r.total_net_loss, 0)) DESC) AS revenue_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cc_call_center_sk = r.cr_call_center_sk
   AND s.sm_ship_mode_sk = r.sm_ship_mode_sk
   AND s.cp_department = r.cp_department
WHERE (s.total_net_profit - COALESCE(r.total_net_loss, 0)) > 1000
ORDER BY net_revenue DESC
LIMIT 50
