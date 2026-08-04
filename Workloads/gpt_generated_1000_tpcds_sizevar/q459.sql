/*
Goal: Identify high‑value customers and items by combining web, catalog and store sales data, inventory levels, promotions and return reasons. The query joins all 16 selected TPC‑DS tables, applies realistic filters, pre‑aggregates inventory, expands a generated price array with UNNEST, uses a correlated EXISTS to keep only customers with at least one store return loss, and reports several aggregates over multiple grouping sets.
*/
WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
),
item_expanded AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_current_price,
        i.i_wholesale_cost,
        ARRAY[i.i_wholesale_cost, i.i_current_price] AS price_array
    FROM item i
),
price_unnested AS (
    SELECT
        ie.i_item_sk,
        ie.i_brand,
        ie.i_current_price,
        price_val
    FROM item_expanded ie
    CROSS JOIN UNNEST(ie.price_array) AS t(price_val)
)
SELECT
    c.c_customer_id,
    i.i_brand,
    w.w_city,
    r.r_reason_desc,
    SUM(ws.ws_net_paid)               AS total_ws_net_paid,
    AVG(cs.cs_sales_price)            AS avg_cs_sales_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_orders,
    MIN(ia.total_qty_on_hand)         AS min_inventory_qty,
    MAX(pu.price_val)                 AS max_price_derived
FROM web_sales ws
JOIN item i                     ON ws.ws_item_sk = i.i_item_sk
JOIN customer c                 ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd   ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp                ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm               ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w                ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p                ON ws.ws_promo_sk = p.p_promo_sk
JOIN catalog_sales cs          
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_bill_customer_sk = c.c_customer_sk
   AND cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   AND cs.cs_warehouse_sk = w.w_warehouse_sk
   AND cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN store_sales ss             
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_customer_sk = c.c_customer_sk
JOIN store s                    ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr           
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = i.i_item_sk
JOIN reason r                   ON sr.sr_reason_sk = r.r_reason_sk
JOIN inventory_agg ia           ON ia.inv_item_sk = i.i_item_sk
                               AND ia.inv_warehouse_sk = w.w_warehouse_sk
JOIN price_unnested pu          ON pu.i_item_sk = i.i_item_sk
WHERE ws.ws_list_price > 50
  AND cs.cs_quantity >= 2
  AND i.i_current_price BETWEEN 20 AND 100
  AND w.w_city = 'Pleasant Grove'
  AND cd.cd_gender = 'M'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_net_loss > 0
    )
GROUP BY GROUPING SETS (
    (c.c_customer_id, i.i_brand),
    (w.w_city),
    (r.r_reason_desc)
)
ORDER BY total_ws_net_paid DESC
LIMIT 100
