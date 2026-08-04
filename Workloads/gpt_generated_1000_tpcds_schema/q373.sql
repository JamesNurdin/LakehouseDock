WITH cs AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > 1
      AND cs_net_paid > 100
      AND cs_sold_date_sk BETWEEN 2451024 AND 2451270
),
ws AS (
    SELECT *
    FROM web_sales
    WHERE ws_quantity > 1
      AND ws_net_paid > 100
),
joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        c.c_customer_id,
        c.c_birth_month,
        cd.cd_credit_rating,
        cp.cp_catalog_page_number,
        w.w_state,
        sm.sm_type,
        p.p_discount_active,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        r.r_reason_desc,
        CASE WHEN cr.cr_return_quantity IS NOT NULL THEN 'Returned' ELSE 'Sold' END AS sale_status,
        ARRAY[cs.cs_quantity, cs.cs_net_paid] AS metrics
    FROM cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cp.cp_catalog_page_number IN (8, 11, 13)
      AND cd.cd_credit_rating IN ('Good', 'Low Risk')
      AND w.w_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
),
metrics_expanded AS (
    SELECT
        j.*, 
        t.metric_value,
        t.metric_position
    FROM joined j
    CROSS JOIN UNNEST(j.metrics) WITH ORDINALITY AS t(metric_value, metric_position)
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY cs_sold_date_sk DESC) AS recent_sale_rank,
        LAG(cs_net_paid) OVER (PARTITION BY c_customer_id ORDER BY cs_sold_date_sk) AS prev_net_paid,
        SUM(cs_net_paid) OVER (
            PARTITION BY c_customer_id 
            ORDER BY cs_sold_date_sk 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_net_paid,
        RANK() OVER (ORDER BY cs_net_profit DESC) AS profit_rank
    FROM metrics_expanded
)
SELECT
    cs_order_number,
    c_customer_id,
    cs_sold_date_sk,
    cs_quantity,
    cs_net_paid,
    cumulative_net_paid,
    sale_status,
    profit_rank,
    recent_sale_rank,
    prev_net_paid,
    metric_value,
    metric_position
FROM ranked
WHERE profit_rank <= 10
EXCEPT
SELECT
    ws.ws_order_number,
    c.c_customer_id,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_net_paid,
    NULL AS cumulative_net_paid,
    'WebSale' AS sale_status,
    NULL AS profit_rank,
    NULL AS recent_sale_rank,
    NULL AS prev_net_paid,
    NULL AS metric_value,
    NULL AS metric_position
FROM ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE ws.ws_net_paid > 5000
