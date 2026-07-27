WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_net_paid,
        cs.cs_quantity,
        d.d_date,
        d.d_year,
        d.d_month_seq
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    cc.cc_manager,
    sm.sm_type,
    sb.d_date AS sale_date,
    SUM(sb.cs_net_paid) AS total_net_paid,
    SUM(sb.cs_quantity) AS total_quantity,
    inv.inv_quantity_on_hand,
    COALESCE(max_inv.max_qty, 0) AS max_inventory_qty,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(sb.cs_net_paid) DESC) AS sales_rank,
    CASE
        WHEN SUM(sb.cs_net_paid) > 20000 THEN 'High'
        WHEN SUM(sb.cs_net_paid) > 10000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_category
FROM sales_base sb
JOIN call_center cc ON sb.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON sb.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON sb.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON sb.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
                     AND inv.inv_date_sk = sb.cs_sold_date_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = sb.cs_sold_date_sk
LEFT JOIN (
    SELECT DISTINCT inv2.inv_warehouse_sk,
           MAX(inv2.inv_quantity_on_hand) AS max_qty
    FROM inventory inv2
    GROUP BY inv2.inv_warehouse_sk
) max_inv ON max_inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE cc.cc_manager = 'Mark Hightower'
  AND w.w_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND inv.inv_quantity_on_hand > 0
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs3
        WHERE cs3.cs_warehouse_sk = w.w_warehouse_sk
          AND cs3.cs_sold_date_sk = sb.cs_sold_date_sk
          AND cs3.cs_quantity > 5
    )
GROUP BY
    w.w_warehouse_name,
    w.w_city,
    cc.cc_manager,
    sm.sm_type,
    sb.d_date,
    inv.inv_quantity_on_hand,
    max_inv.max_qty
ORDER BY total_net_paid DESC
LIMIT 100
