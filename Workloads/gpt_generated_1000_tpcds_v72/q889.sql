WITH sales_summary AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        cc.cc_name,
        p_cs.p_promo_name AS cs_promo_name,
        p_ws.p_promo_name AS ws_promo_name,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_ext,
        SUM(ws.ws_ext_sales_price) AS web_sales_ext,
        SUM(cs.cs_quantity) AS catalog_quantity,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        CASE
            WHEN cc.cc_state = 'CA' THEN 'West'
            WHEN cc.cc_state = 'NY' THEN 'East'
            ELSE 'Other'
        END AS region_group
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
      AND cs.cs_quantity > 5
      AND ws.ws_net_paid > 1000
      AND p_cs.p_discount_active = 'Y'
      AND i.inv_quantity_on_hand > 500
    GROUP BY
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        cc.cc_name,
        p_cs.p_promo_name,
        p_ws.p_promo_name,
        CASE
            WHEN cc.cc_state = 'CA' THEN 'West'
            WHEN cc.cc_state = 'NY' THEN 'East'
            ELSE 'Other'
        END
)
SELECT
    s.w_warehouse_id,
    s.w_city,
    s.w_state,
    s.cc_name,
    s.cs_promo_name,
    s.ws_promo_name,
    s.catalog_sales_ext,
    s.web_sales_ext,
    (s.catalog_sales_ext + s.web_sales_ext) AS total_sales,
    s.catalog_quantity,
    s.web_quantity,
    s.catalog_orders,
    s.web_orders,
    s.region_group,
    ROW_NUMBER() OVER (PARTITION BY s.region_group ORDER BY (s.catalog_sales_ext + s.web_sales_ext) DESC) AS rn_within_region,
    (SELECT AVG(p_cost) FROM promotion WHERE p_discount_active = 'Y') AS avg_active_promo_cost
FROM sales_summary s
WHERE (s.catalog_sales_ext + s.web_sales_ext) > (
    SELECT AVG(inner_total)
    FROM (
        SELECT SUM(cs.cs_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS inner_total
        FROM catalog_sales cs
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
        GROUP BY w.w_warehouse_id
    ) t
)
ORDER BY total_sales DESC
LIMIT 100
