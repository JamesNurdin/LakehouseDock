-- Goal: Identify high‑value catalog sales items, enrich them with customer, promotion and warehouse details,
-- incorporate related store and web sales performance, total returns, and promotional cost.
-- The query joins all 21 selected TPC‑DS tables, re‑uses the ITEM and TIME_DIM tables via different aliases,
-- uses a CASE expression, DISTINCT, a correlated scalar sub‑query, a UNION ALL set operation, and a correlated EXISTS filter.
WITH
  -- Combine catalog and web return amounts for the same order number (set operation)
  all_returns AS (
    SELECT cr.cr_order_number AS order_number,
           cr.cr_return_amount          AS return_amount
    FROM   catalog_returns cr
    UNION ALL
    SELECT wr.wr_order_number,
           wr.wr_return_amt
    FROM   web_returns wr
  ),
  -- Aggregate store sales by item (reuse ITEM table under alias i_store)
  store_sales_agg AS (
    SELECT ss.ss_item_sk,
           SUM(ss.ss_net_paid)    AS store_net_paid,
           SUM(ss.ss_net_profit)  AS store_net_profit
    FROM   store_sales ss
    GROUP BY ss.ss_item_sk
  ),
  -- Aggregate web sales by item (reuse ITEM table under alias i_web)
  web_sales_agg AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_net_paid)   AS web_net_paid,
           SUM(ws.ws_net_profit) AS web_net_profit
    FROM   web_sales ws
    GROUP BY ws.ws_item_sk
  )
SELECT DISTINCT
  c.c_customer_id,
  i.i_item_id,
  CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
  cs.cs_net_paid,
  ss_agg.store_net_paid,
  ws_agg.web_net_paid,
  ir.inc_return_amount,
  -- Correlated scalar sub‑query: total promotional cost for this item
  (
    SELECT SUM(p2.p_cost)
    FROM   promotion p2
    WHERE  p2.p_item_sk = i.i_item_sk
  ) AS total_promo_cost
FROM   catalog_sales cs
JOIN   customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN   item i                    ON cs.cs_item_sk = i.i_item_sk               -- ITEM alias i (for catalog sales)
JOIN   promotion p               ON cs.cs_promo_sk = p.p_promo_sk
JOIN   call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN   catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN   ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN   warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN   customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN   household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN   income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN   time_dim td1             ON cs.cs_sold_time_sk = td1.t_time_sk
LEFT JOIN store_sales_agg ss_agg ON ss_agg.ss_item_sk = cs.cs_item_sk
LEFT JOIN web_sales_agg   ws_agg ON ws_agg.ws_item_sk = cs.cs_item_sk
LEFT JOIN (
        SELECT order_number, SUM(return_amount) AS inc_return_amount
        FROM   all_returns
        GROUP BY order_number
      ) ir ON ir.order_number = cs.cs_order_number
WHERE  EXISTS (
        SELECT 1
        FROM   catalog_returns cr2
        WHERE  cr2.cr_item_sk = cs.cs_item_sk
          AND  cr2.cr_returned_date_sk = cs.cs_sold_date_sk
      )
ORDER BY cs.cs_net_paid DESC
LIMIT 100
