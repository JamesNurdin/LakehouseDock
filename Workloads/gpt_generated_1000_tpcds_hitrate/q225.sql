WITH joined_data AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    ca.ca_state,
    hd.hd_vehicle_count,
    p.p_discount_active,
    ss.ss_quantity,
    ss.ss_net_paid,
    ws.ws_net_paid,
    cs.cs_net_paid_inc_ship,
    sr.sr_net_loss,
    inv.inv_quantity_on_hand,
    inv_agg.total_inventory_qty
  FROM
    store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
      AND sr.sr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    CROSS JOIN LATERAL (
      SELECT sum(inv2.inv_quantity_on_hand) AS total_inventory_qty
      FROM inventory inv2
      WHERE inv2.inv_item_sk = i.i_item_sk
    ) AS inv_agg
  WHERE
    ca.ca_state = 'CA'
    AND hd.hd_vehicle_count >= 2
    AND p.p_discount_active = 'Y'
    AND inv.inv_quantity_on_hand < 200
    AND ss.ss_quantity > 1
),
item_agg AS (
  SELECT
    i_item_id,
    i_product_name,
    i_category,
    sum(ss_net_paid) AS store_sales_net,
    sum(ws_net_paid) AS web_sales_net,
    sum(cs_net_paid_inc_ship) AS catalog_sales_net,
    sum(coalesce(sr_net_loss, 0)) AS total_return_loss,
    max(total_inventory_qty) AS total_inventory_qty
  FROM joined_data
  GROUP BY
    i_item_id,
    i_product_name,
    i_category
),
ranked_items AS (
  SELECT
    ia.*,
    ROW_NUMBER() OVER (PARTITION BY ia.i_category ORDER BY (ia.store_sales_net + ia.web_sales_net + ia.catalog_sales_net) DESC) AS category_rank
  FROM item_agg ia
)
SELECT
  i_item_id,
  i_product_name,
  i_category,
  store_sales_net,
  web_sales_net,
  catalog_sales_net,
  total_return_loss,
  total_inventory_qty,
  category_rank
FROM ranked_items
WHERE category_rank <= 5
ORDER BY i_category, category_rank
LIMIT 100
