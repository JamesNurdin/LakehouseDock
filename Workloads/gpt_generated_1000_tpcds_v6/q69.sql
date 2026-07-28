-- goal: Identify the top‑ranked items for each customer based on combined catalog and web net payments,
-- including inventory levels, promotion activity and several business filters.
WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_warehouse_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900   -- date range filter
      AND cs.cs_quantity > 0
      AND cs.cs_item_sk IS NOT NULL
    GROUP BY
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900   -- same date window
      AND ws.ws_quantity > 0
      AND ws.ws_item_sk IS NOT NULL
    GROUP BY
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk
)
SELECT
    c.c_customer_id,
    hd.hd_buy_potential,
    i.i_item_id,
    i.i_product_name,
    COALESCE(cs_agg.total_net_paid, 0) + COALESCE(ws_agg.total_net_paid, 0) AS total_net_paid,
    CASE
        WHEN (
            SELECT COUNT(*)
            FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
              AND p2.p_discount_active = 'Y'
        ) > 0 THEN 'Promotion'
        ELSE 'No Promotion'
    END AS promo_status,
    inv_agg.total_qty_on_hand,
    RANK() OVER (
        PARTITION BY c.c_customer_id
        ORDER BY COALESCE(cs_agg.total_net_paid, 0) + COALESCE(ws_agg.total_net_paid, 0) DESC
    ) AS sales_rank
FROM customer c
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_sales_agg cs_agg
  ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN web_sales_agg ws_agg
  ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN item i
  ON i.i_item_sk = COALESCE(cs_agg.cs_item_sk, ws_agg.ws_item_sk)
LEFT JOIN inventory_agg inv_agg
  ON inv_agg.inv_item_sk = i.i_item_sk
     AND inv_agg.inv_warehouse_sk = COALESCE(cs_agg.cs_warehouse_sk, ws_agg.ws_warehouse_sk)
LEFT JOIN call_center cc
  ON cc.cc_call_center_sk = cs_agg.cs_call_center_sk
LEFT JOIN catalog_page cp
  ON cp.cp_catalog_page_sk = cs_agg.cs_catalog_page_sk
LEFT JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = COALESCE(cs_agg.cs_ship_mode_sk, ws_agg.ws_ship_mode_sk)
LEFT JOIN warehouse w
  ON w.w_warehouse_sk = COALESCE(cs_agg.cs_warehouse_sk, ws_agg.ws_warehouse_sk)
LEFT JOIN promotion p
  ON p.p_promo_sk = COALESCE(cs_agg.cs_promo_sk, ws_agg.ws_promo_sk)
LEFT JOIN web_page wp
  ON wp.wp_web_page_sk = ws_agg.ws_web_page_sk
LEFT JOIN web_site wsit
  ON wsit.web_site_sk = ws_agg.ws_web_site_sk
WHERE i.i_brand_id = 5                                 -- brand filter
  AND w.w_state = 'CA'                                 -- warehouse location filter
  AND cc.cc_class = 'Class A'                         -- call‑center class filter
  AND p.p_discount_active = 'Y'                       -- active promotion filter
  AND hd.hd_vehicle_count > 2                         -- household vehicle count filter
  AND cp.cp_catalog_number IN (12, 15)                -- catalog page number filter
ORDER BY total_net_paid DESC
