/* goal: Identify items that have generated profit in both store sales and web sales, enrich them with aggregated sales quantities, latest inventory level, and keep any unmatched store‑sales or store information via a full outer join. The result is paginated. */
WITH sales_items AS (
    SELECT DISTINCT i.i_item_id,
           s.s_store_id,
           ss.ss_net_profit,
           ss.ss_sold_date_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_net_profit > 0
),
web_items AS (
    SELECT DISTINCT i.i_item_id,
           ws.ws_sold_date_sk,
           ws.ws_net_paid
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_net_paid > 0
),
intersect_items AS (
    SELECT i_item_id FROM sales_items
    INTERSECT
    SELECT i_item_id FROM web_items
),
full_store_sales AS (
    SELECT ss.ss_item_sk,
           ss.ss_store_sk,
           ss.ss_quantity,
           s.s_store_name
    FROM store_sales ss
    FULL OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_quantity > 0 OR s.s_store_name IS NOT NULL
),
store_agg AS (
    SELECT ss_item_sk,
           SUM(ss_quantity) AS total_store_qty
    FROM store_sales
    GROUP BY ss_item_sk
),
web_agg AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_web_qty
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT DISTINCT
       i.i_item_id,
       i.i_product_name,
       COALESCE(sa.total_store_qty, 0)      AS total_store_quantity,
       COALESCE(wa.total_web_qty, 0)        AS total_web_quantity,
       inv_latest.inv_quantity_on_hand      AS latest_inventory_qty,
       fss.ss_quantity                      AS store_sales_quantity,
       fss.s_store_name                     AS store_name
FROM intersect_items ii
JOIN item i ON i.i_item_id = ii.i_item_id
LEFT JOIN store_agg sa ON sa.ss_item_sk = i.i_item_sk
LEFT JOIN web_agg wa   ON wa.ws_item_sk = i.i_item_sk
LEFT JOIN full_store_sales fss ON fss.ss_item_sk = i.i_item_sk
LEFT JOIN LATERAL (
    SELECT inv.inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
    ORDER BY inv.inv_quantity_on_hand DESC
    LIMIT 1
) AS inv_latest ON TRUE
ORDER BY i.i_item_id
OFFSET 0 LIMIT 100
