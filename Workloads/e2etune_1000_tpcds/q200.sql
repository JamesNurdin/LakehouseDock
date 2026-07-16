WITH sales_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages_visited
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY sm.sm_ship_mode_id, sm.sm_carrier
),
returns_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        SUM(cr.cr_net_loss) AS total_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
    GROUP BY sm.sm_ship_mode_id
)
SELECT
    s.sm_ship_mode_id,
    s.sm_carrier,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_loss, 0) AS total_loss,
    (s.total_profit - COALESCE(r.total_loss, 0)) AS net_profit_after_returns,
    s.sales_cnt,
    COALESCE(r.returns_cnt, 0) AS returns_cnt,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    s.distinct_pages_visited,
    RANK() OVER (ORDER BY (s.total_profit - COALESCE(r.total_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r ON s.sm_ship_mode_id = r.sm_ship_mode_id
ORDER BY net_profit_after_returns DESC
LIMIT 10
