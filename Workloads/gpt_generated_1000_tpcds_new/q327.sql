/*
  Goal: Analyze yearly sales performance by brand and state, combining store, catalog, and web sales with inventory levels, customer demographics, and promotion channel details. The query also identifies items sold in the catalog but never in stores, provides subtotals with ROLLUP, expands promotion channel strings into rows, and limits the result to the top 100 rows.
*/
WITH
  -- Pre‑aggregate inventory to get total on‑hand per item‑warehouse
  inv_agg AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_warehouse_sk,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
  ),
  -- Items that appear in catalog_sales but not in store_sales
  diff_items AS (
    SELECT cs.cs_item_sk
    FROM catalog_sales cs
    EXCEPT
    SELECT ss.ss_item_sk
    FROM store_sales ss
  )
SELECT
  d.d_year,
  i.i_brand,
  cc.cc_state,
  SUM(ss.ss_net_paid)               AS store_sales_total,
  SUM(cs.cs_net_paid)               AS catalog_sales_total,
  SUM(ws.ws_net_paid)               AS web_sales_total,
  SUM(ia.total_on_hand)             AS inventory_on_hand,
  COUNT(DISTINCT c.c_customer_sk)   AS distinct_customers,
  COUNT(DISTINCT di.cs_item_sk)      AS catalog_not_in_store_items,
  ARRAY_AGG(DISTINCT TRIM(channel)) AS promotion_channels
FROM date_dim d
  -- Sales tables (all linked to the same date surrogate key)
  JOIN store_sales ss   ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN web_sales ws     ON ws.ws_sold_date_sk = d.d_date_sk
  -- Inventory and its pre‑aggregation
  JOIN inventory inv     ON inv.inv_date_sk = d.d_date_sk
  JOIN inv_agg ia        ON ia.inv_item_sk = inv.inv_item_sk
                        AND ia.inv_warehouse_sk = inv.inv_warehouse_sk
  -- Dimensional tables
  JOIN item i                 ON i.i_item_sk = ss.ss_item_sk
  JOIN customer c             ON c.c_customer_sk = ss.ss_customer_sk
  JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
  JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
  JOIN income_band ib           ON ib.ib_income_band_sk = hd.hd_income_band_sk
  JOIN call_center cc          ON cc.cc_closed_date_sk = d.d_date_sk
  JOIN catalog_page cp         ON cp.cp_start_date_sk = d.d_date_sk
  JOIN promotion p             ON p.p_start_date_sk = d.d_date_sk
  JOIN warehouse w             ON w.w_warehouse_sk = cs.cs_warehouse_sk
  LEFT JOIN diff_items di      ON di.cs_item_sk = cs.cs_item_sk
  -- Expand the comma‑separated channel list stored in p.p_channel_details
  CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel)
WHERE
  d.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND cc.cc_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
          AND cs2.cs_quantity > 5
      )
GROUP BY ROLLUP (d.d_year, i.i_brand, cc.cc_state)
ORDER BY d.d_year DESC, i.i_brand, cc.cc_state
LIMIT 100
