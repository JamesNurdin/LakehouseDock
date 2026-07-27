WITH item_metrics AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        SUM(ws.ws_quantity) AS total_ws_quantity,
        SUM(ws.ws_ext_sales_price) AS total_ws_sales,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_qty,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_qty,
        COALESCE(SUM(p.p_cost), 0) AS total_promo_cost,
        COUNT(DISTINCT w.w_warehouse_sk) AS warehouse_count
    FROM item i
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20
      AND i.i_brand = 'Brand#23'
      AND ws.ws_sold_date_sk BETWEEN 2451910 AND 2451920
      AND inv.inv_quantity_on_hand >= 100
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_brand, i.i_category
)
SELECT
    im.i_item_id,
    im.i_brand,
    im.i_category,
    im.total_ws_quantity,
    im.total_ws_sales,
    im.total_inventory_qty,
    im.total_return_qty,
    im.total_promo_cost,
    im.warehouse_count,
    (im.total_ws_sales - im.total_promo_cost) AS net_sales_minus_promo,
    (SELECT AVG(total_ws_sales) FROM item_metrics) AS avg_sales_all_items
FROM item_metrics im
WHERE im.total_ws_quantity > 0
  AND im.total_return_qty < im.total_ws_quantity
  AND (im.total_ws_sales / NULLIF(im.total_ws_quantity, 0)) > 50
  AND im.total_inventory_qty > im.total_return_qty
  AND im.warehouse_count >= 1
ORDER BY net_sales_minus_promo DESC
LIMIT 100
