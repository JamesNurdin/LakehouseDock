WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
),
intersect_keys AS (
    SELECT sr.sr_customer_sk AS cust_sk FROM store_returns sr
    INTERSECT
    SELECT wr.wr_refunded_customer_sk AS cust_sk FROM web_returns wr
),
final_data AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        t.t_hour,
        w.w_warehouse_name,
        sm.sm_type,
        p.p_promo_name,
        cc.cc_name,
        inv_agg.total_qty_on_hand,
        CASE WHEN cs.cs_net_paid > 1000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.cs_net_paid DESC) AS rn,
        u.discount_component,
        l.total_ws_qty,
        tag.tag AS tag_name
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN inv_agg ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    -- UNNEST discount components (array expansion)
    LEFT JOIN UNNEST(ARRAY[cs.cs_ext_discount_amt, cs.cs_coupon_amt]) AS u (discount_component) ON TRUE
    -- LATERAL sub‑query to compute total web‑sales quantity for the customer
    LEFT JOIN LATERAL (
        SELECT SUM(ws_quantity) AS total_ws_qty
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = c.c_customer_sk
    ) l ON TRUE
    -- Cross join a small computed set and expand it
    CROSS JOIN (SELECT ARRAY['A','B','C'] AS tags) tag_set
    CROSS JOIN UNNEST(tag_set.tags) AS tag(tag)
    WHERE c.c_email_address LIKE '%@%'
      AND w.w_state = 'CA'
      AND sm.sm_type IN ('OVERNIGHT', 'EXPRESS')
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2450920
      AND cs.cs_net_paid IS NOT NULL
      AND c.c_customer_sk IN (SELECT cust_sk FROM intersect_keys)
)
SELECT
    c_customer_sk,
    c_email_address,
    cs_order_number,
    cs_sold_date_sk,
    t_hour,
    w_warehouse_name,
    sm_type,
    p_promo_name,
    cc_name,
    total_qty_on_hand,
    sales_category,
    rn,
    discount_component,
    total_ws_qty,
    tag_name
FROM final_data
WHERE rn <= 10
ORDER BY total_qty_on_hand DESC, sales_category
LIMIT 100
