WITH
  -- Expand a category into an array of dummy codes
  category_array AS (
    SELECT i_category,
           ARRAY['A', 'B', 'C'] AS cat_codes
    FROM item
    WHERE i_category IS NOT NULL
  ),
  -- Set of catalog item keys
  catalog_item_set AS (
    SELECT cs_item_sk
    FROM catalog_sales
  ),
  -- Set of store‑return item keys
  store_return_item_set AS (
    SELECT sr_item_sk
    FROM store_returns
  ),
  -- Items that appear in catalog_sales but not in store_returns
  item_excluding_returns AS (
    SELECT cs_item_sk AS item_sk
    FROM catalog_item_set
    EXCEPT
    SELECT sr_item_sk AS item_sk
    FROM store_return_item_set
  )
SELECT
  cs.cs_order_number,
  cs.cs_net_profit,
  i1.i_item_id,
  i1.i_category,
  i1.i_class,
  cc.cc_name,
  sm.sm_type,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  r.r_reason_desc,
  inv.inv_quantity_on_hand,
  CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
  code AS category_code
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i1               -- first role of ITEM (catalog sales)
  ON cs.cs_item_sk = i1.i_item_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
FULL OUTER JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i1.i_item_sk               -- bridge through ITEM
JOIN household_demographics hd_store
  ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
  AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN item i2               -- second role of ITEM (store sales / inventory)
  ON ss.ss_item_sk = i2.i_item_sk
JOIN inventory inv
  ON i2.i_item_sk = inv.inv_item_sk
LEFT JOIN category_array ca
  ON i1.i_category = ca.i_category
CROSS JOIN UNNEST(ca.cat_codes) AS t(code)
WHERE cs.cs_item_sk IN (SELECT item_sk FROM item_excluding_returns)
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_ticket_number = cs.cs_order_number
          AND ss2.ss_item_sk = cs.cs_item_sk
      )
GROUP BY
  cs.cs_order_number,
  cs.cs_net_profit,
  i1.i_item_id,
  i1.i_category,
  i1.i_class,
  cc.cc_name,
  sm.sm_type,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  r.r_reason_desc,
  inv.inv_quantity_on_hand,
  CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END,
  code
ORDER BY cs.cs_net_profit DESC
LIMIT 100
