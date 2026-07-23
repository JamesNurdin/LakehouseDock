WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_promo_sk,
        cs_call_center_sk,
        cs_warehouse_sk,
        cs_ship_mode_sk,
        cs_sold_date_sk,
        cs_order_number,
        SUM(cs_net_paid) AS total_cs_net_paid,
        SUM(cs_quantity) AS total_cs_quantity,
        COUNT(*) AS cs_sales_cnt
    FROM catalog_sales
    WHERE cs_quantity > 0
      AND cs_net_paid > 0
      AND cs_sold_date_sk IS NOT NULL
    GROUP BY
        cs_item_sk,
        cs_promo_sk,
        cs_call_center_sk,
        cs_warehouse_sk,
        cs_ship_mode_sk,
        cs_sold_date_sk,
        cs_order_number
    HAVING SUM(cs_net_paid) > 10000
),
promo_agg AS (
    SELECT
        p.p_promo_id,
        d_cs.d_year AS sold_year,
        cc.cc_name,
        w.w_warehouse_name,
        sm.sm_type,
        ca.ca_state,
        SUM(cs_agg.total_cs_net_paid) AS total_net_paid,
        SUM(cs_agg.total_cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs_agg.cs_order_number) AS distinct_orders,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount
    FROM cs_agg
    JOIN promotion p ON cs_agg.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_cs ON cs_agg.cs_sold_date_sk = d_cs.d_date_sk
    JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs_agg.cs_order_number
        AND cr.cr_item_sk = cs_agg.cs_item_sk
    WHERE p.p_channel_dmail = 'Y'
      AND p.p_channel_email = 'N'
      AND w.w_state = 'CA'
      AND ca.ca_state = 'TX'
      AND d_cs.d_year = 2002
      AND cc.cc_division = 1
    GROUP BY
        p.p_promo_id,
        d_cs.d_year,
        cc.cc_name,
        w.w_warehouse_name,
        sm.sm_type,
        ca.ca_state
    HAVING SUM(cs_agg.total_cs_net_paid) > 50000
       AND COUNT(DISTINCT cs_agg.cs_order_number) > 10
)
SELECT
    p_promo_id,
    sold_year,
    cc_name,
    w_warehouse_name,
    sm_type,
    ca_state,
    total_net_paid,
    total_quantity,
    distinct_orders,
    total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_net_paid DESC) AS rn,
    CASE WHEN total_quantity > 5000 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category
FROM promo_agg
ORDER BY total_net_paid DESC
LIMIT 100
