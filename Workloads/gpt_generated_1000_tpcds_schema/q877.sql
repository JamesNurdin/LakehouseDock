WITH
  -- Catalog Sales fact with its dimensions
  cs AS (
    SELECT
      cs.cs_sold_date_sk      AS date_sk,
      cs.cs_sold_time_sk      AS time_sk,
      cs.cs_call_center_sk,
      cs.cs_ship_mode_sk,
      cs.cs_item_sk,
      cs.cs_bill_customer_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_bill_addr_sk,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_coupon_amt,
      cs.cs_net_profit,
      cc.cc_state,
      sm.sm_carrier,
      d.d_year
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001                         -- predicate 1
      AND sm.sm_carrier = 'FEDEX'                -- predicate 2
      AND cs.cs_quantity > 5                     -- predicate 3
  ),

  -- Web Sales fact with its dimensions
  ws AS (
    SELECT
      ws.ws_sold_date_sk      AS date_sk,
      ws.ws_sold_time_sk      AS time_sk,
      ws.ws_ship_mode_sk,
      ws.ws_item_sk,
      ws.ws_bill_customer_sk,
      ws.ws_bill_hdemo_sk,
      ws.ws_bill_addr_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_coupon_amt,
      ws.ws_net_profit,
      sm.sm_carrier,
      d.d_year,
      w.web_country
    FROM web_sales ws
    JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm             ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i                   ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c               ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site w               ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2001                         -- predicate 1 (re‑used)
      AND sm.sm_carrier = 'FEDEX'                -- predicate 2 (re‑used)
      AND ws.ws_quantity > 10                    -- predicate 4
  ),

  -- Store Returns fact with its dimensions
  sr AS (
    SELECT
      sr.sr_returned_date_sk AS date_sk,
      sr.sr_return_time_sk    AS time_sk,
      sr.sr_item_sk,
      sr.sr_customer_sk,
      sr.sr_hdemo_sk,
      sr.sr_addr_sk,
      sr.sr_store_sk,
      sr.sr_reason_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss,
      s.s_state,
      r.r_reason_desc,
      d.d_year
    FROM store_returns sr
    JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t               ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i                   ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c               ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca      ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s                  ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r                 ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001                         -- predicate 1 (re‑used)
      AND s.s_state = 'CA'                       -- predicate 5
  ),

  -- Item keys that appear both in high‑quantity catalog sales and in returns > 2 units
  intersect_items AS (
    SELECT cs_item_sk AS item_sk FROM cs WHERE cs_quantity > 5
    INTERSECT
    SELECT sr_item_sk FROM sr WHERE sr_return_quantity > 2
  )

SELECT
  COALESCE(t.year, 0)                     AS year,
  COALESCE(t.carrier, 'ALL')               AS carrier,
  SUM(t.sales)                             AS total_sales,
  AVG(t.profit)                            AS avg_profit,
  COUNT(*)                                 AS txn_cnt,
  MIN(t.sales)                             AS min_sale,
  MAX(t.sales)                             AS max_sale
FROM (
  -- Catalog sales rows that satisfy the intersected item list and an EXISTS filter
  SELECT
    d.d_year               AS year,
    sm.sm_carrier          AS carrier,
    cs.cs_net_paid         AS sales,
    cs.cs_net_profit       AS profit,
    cs.cs_item_sk
  FROM cs
  JOIN date_dim d          ON cs.date_sk = d.d_date_sk
  JOIN ship_mode sm        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cs.cs_item_sk IN (SELECT item_sk FROM intersect_items)
    AND EXISTS (SELECT 1 FROM store_returns sr2
                WHERE sr2.sr_item_sk = cs.cs_item_sk
                  AND sr2.sr_return_quantity > 5)

  UNION ALL

  -- Web sales rows (same intersect filter, no extra EXISTS needed)
  SELECT
    d.d_year,
    sm.sm_carrier,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ws.ws_item_sk
  FROM ws
  JOIN date_dim d          ON ws.date_sk = d.d_date_sk
  JOIN ship_mode sm        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE ws.ws_item_sk IN (SELECT item_sk FROM intersect_items)

  UNION ALL

  -- Store return rows – treat return amount as negative sales
  SELECT
    d.d_year,
    s.s_state               AS carrier,
    -sr.sr_return_amt       AS sales,
    -sr.sr_net_loss         AS profit,
    sr.sr_item_sk
  FROM sr
  JOIN date_dim d          ON sr.date_sk = d.d_date_sk
  JOIN store s              ON sr.sr_store_sk = s.s_store_sk
) t
GROUP BY GROUPING SETS ((year, carrier), (year), ())
HAVING SUM(t.sales) > 1000                     -- filter on aggregated sales
ORDER BY year DESC, carrier
