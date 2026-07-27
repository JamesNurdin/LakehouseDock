WITH sales_agg AS (
    SELECT
        sm.sm_type,
        p.p_promo_name,
        r.r_reason_desc,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        (SELECT MAX(p2.p_cost) FROM promotion p2) AS max_promo_cost
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ws.ws_net_paid_inc_tax > 1000
      AND wp.wp_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND sm.sm_type = 'AIR'
    GROUP BY
        sm.sm_type,
        p.p_promo_name,
        r.r_reason_desc
)
SELECT
    sm_type,
    p_promo_name,
    r_reason_desc,
    SUM(total_net_paid) AS sum_total_net_paid,
    SUM(total_return_amt) AS sum_total_return_amt,
    SUM(order_cnt) AS sum_order_cnt,
    SUM(total_net_paid) / NULLIF(SUM(order_cnt), 0) AS avg_paid_per_order,
    MAX(max_promo_cost) AS max_promo_cost
FROM sales_agg
WHERE total_net_paid > 5000
GROUP BY GROUPING SETS (
    (sm_type, p_promo_name, r_reason_desc),
    (sm_type, p_promo_name),
    (sm_type),
    ()
)
ORDER BY sum_total_net_paid DESC
LIMIT 100
