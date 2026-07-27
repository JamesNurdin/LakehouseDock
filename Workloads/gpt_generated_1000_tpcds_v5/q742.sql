WITH agg_inventory AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_date_sk BETWEEN 2450800 AND 2450810
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_net_profit,
    d_sold.d_year,
    i.i_category,
    i.i_brand_id,
    w.w_warehouse_name,
    w.w_warehouse_sq_ft,
    sm.sm_type,
    ca.ca_state,
    wp.wp_url,
    wp.wp_image_count,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    RANK() OVER (PARTITION BY i.i_category ORDER BY cs.cs_net_paid DESC) AS category_sales_rank,
    SUM(cs.cs_quantity) OVER (PARTITION BY i.i_item_sk ORDER BY d_sold.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_quantity,
    inv.total_on_hand,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
        WHERE i2.i_category = i.i_category
    ) AS avg_category_profit
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN agg_inventory inv ON cs.cs_item_sk = inv.inv_item_sk AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_brand_id IN (3, 5)
  AND ca.ca_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND w.w_warehouse_sq_ft > 15000
  AND cs.cs_quantity > 2
  AND cs.cs_net_paid > 100.00
  AND wp.wp_image_count BETWEEN 2 AND 5
ORDER BY category_sales_rank ASC, cs.cs_net_paid DESC
LIMIT 100
