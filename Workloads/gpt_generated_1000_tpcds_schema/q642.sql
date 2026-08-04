-- Goal: Identify the top‑ranked web sales orders (by net profit) after filtering on several business rules, while
-- joining every selected TPC‑DS table, applying complex analytics such as GROUPING SETS, window ranking,
-- a CASE‑based profit tier, a LATERAL sub‑query for total returns, an anti‑join, and a set difference (EXCEPT).
WITH
  -- 1. Pre‑aggregate inventory per item / warehouse (CTE)
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),
  -- 2. Orders that appear in web_sales but NOT in catalog_returns (EXCEPT)
  order_diff AS (
    SELECT ws_order_number
    FROM web_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
  ),
  -- 3. Core join of all tables (each table appears at least once)
  joined_data AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_quantity,
      ws.ws_sales_price,
      ws.ws_net_profit,
      i.i_item_id,
      i.i_current_price,
      w.w_warehouse_sk,
      w.w_state,
      wsite.web_site_sk,
      wsite.web_country,
      p.p_promo_sk,
      p.p_discount_active,
      sm.sm_ship_mode_sk,
      cd.cd_gender,
      hd.hd_buy_potential,
      ib.ib_lower_bound,
      cc.cc_market_manager,
      -- profit tier (CASE)
      CASE
        WHEN ws.ws_net_profit >= 1000 THEN 'High'
        WHEN ws.ws_net_profit >= 0   THEN 'Medium'
        ELSE 'Low'
      END AS profit_category,
      agg.total_qty,
      -- LATERAL sub‑query returning total returned quantity for this item (catalog + store)
      ret.total_return_qty
    FROM web_sales ws
    JOIN item i               ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm         ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w          ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p          ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN call_center cc       ON EXISTS (SELECT 1 FROM catalog_returns cr WHERE cr.cr_call_center_sk = cc.cc_call_center_sk AND cr.cr_item_sk = i.i_item_sk)
    JOIN inv_agg agg          ON agg.inv_item_sk = i.i_item_sk AND agg.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN LATERAL (
      SELECT
        COALESCE(SUM(cr2.cr_return_quantity),0) + COALESCE(SUM(sr2.sr_return_quantity),0) AS total_return_qty
      FROM catalog_returns cr2
      LEFT JOIN store_returns sr2 ON sr2.sr_item_sk = cr2.cr_item_sk
      WHERE cr2.cr_item_sk = i.i_item_sk
    ) ret ON TRUE
    WHERE ws.ws_sales_price > 100                         -- predicate 1
      AND w.w_state = 'CA'                                 -- predicate 2
      AND p.p_discount_active = 'Y'                        -- predicate 3
      AND i.i_current_price BETWEEN 10 AND 1000           -- predicate 4
      AND wsite.web_country = 'United States'             -- predicate 5
      AND cd.cd_gender = 'M'                               -- predicate 6 (extra)
      AND hd.hd_buy_potential = '0-500'                    -- predicate 7 (extra)
      AND NOT EXISTS (                                      -- anti‑join: keep rows with no matching store return on same date
            SELECT 1
            FROM store_returns sr_n
            WHERE sr_n.sr_item_sk = ws.ws_item_sk
              AND sr_n.sr_returned_date_sk = ws.ws_sold_date_sk
          )
      AND ws.ws_order_number IN (SELECT ws_order_number FROM order_diff) -- uses EXCEPT result
  )
-- 4. Aggregate with multiple GROUPING SETS
SELECT
  jd.ws_order_number,
  jd.ws_sold_date_sk,
  jd.i_item_id,
  SUM(jd.ws_quantity)            AS total_quantity,
  SUM(jd.ws_net_profit)          AS total_profit,
  jd.profit_category,
  MAX(jd.total_return_qty)       AS total_return_qty,
  MAX(jd.total_qty)              AS inventory_on_hand,
  RANK() OVER (PARTITION BY jd.web_site_sk ORDER BY SUM(jd.ws_net_profit) DESC) AS profit_rank,
  jd.w_state,
  jd.web_country
FROM joined_data jd
GROUP BY GROUPING SETS (
        (jd.ws_order_number, jd.ws_sold_date_sk, jd.i_item_id, jd.profit_category, jd.web_site_sk, jd.w_state, jd.web_country),
        (jd.ws_order_number, jd.ws_sold_date_sk, jd.profit_category, jd.web_site_sk, jd.w_state, jd.web_country),
        (jd.ws_order_number, jd.ws_sold_date_sk, jd.web_site_sk, jd.w_state, jd.web_country)
      )
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
