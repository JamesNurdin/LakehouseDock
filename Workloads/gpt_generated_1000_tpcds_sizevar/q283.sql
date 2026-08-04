/*
  goal: Identify high‑value catalog sales orders for 2001 that were shipped via FEDEX, processed by California call centers, and exceed $5,000 net paid (incl. ship). For each order we compute the average net paid (incl. ship) for its call center, rank orders within each carrier, label order size, and keep only orders that appear in the intersection of two independent order‑number sets.
*/
WITH
  -- Join all six tables using only the allowed foreign‑key relationships
  joined AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_paid_inc_ship,
      cs.cs_quantity,
      d_sold.d_date        AS sold_date,
      d_ship.d_date        AS ship_date,
      cc.cc_name           AS call_center_name,
      cc.cc_state,
      cp.cp_department,
      cp.cp_type,
      sm.sm_carrier,
      sm.sm_contract,
      st.s_store_name,
      st.s_state AS store_state,
      -- correlated scalar sub‑query: average net paid (incl. ship) for the same call center
      (
        SELECT AVG(cs2.cs_net_paid_inc_ship)
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = cs.cs_call_center_sk
      ) AS avg_center_paid
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk   = d_sold.d_date_sk
    JOIN date_dim d_ship
      ON cs.cs_ship_date_sk   = d_ship.d_date_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN store st
      ON st.s_closed_date_sk = d_ship.d_date_sk   -- store linked via its closed‑date surrogate key
    WHERE d_sold.d_year = 2001                      -- predicate 1: year filter
      AND sm.sm_carrier = 'FEDEX'                  -- predicate 2: carrier filter
      AND cc.cc_state = 'CA'                       -- predicate 3: call‑center state filter
      AND cs.cs_net_paid_inc_ship > 5000          -- predicate 4: revenue filter
  ),

  -- Two independent order‑number selections whose intersection will be used later
  intersected_orders AS (
    SELECT cs_order_number FROM catalog_sales WHERE cs_net_paid_inc_ship > 8000
    INTERSECT
    SELECT cs_order_number FROM catalog_sales WHERE cs_quantity > 15
  )
SELECT
  j.cs_order_number                         AS order_number,
  j.cs_net_paid_inc_ship                    AS net_paid_inc_ship,
  j.cs_quantity                             AS quantity,
  j.sold_date,
  j.ship_date,
  j.call_center_name,
  j.cp_department                           AS department,
  j.sm_carrier                              AS carrier,
  j.avg_center_paid,
  RANK() OVER (PARTITION BY j.sm_carrier ORDER BY j.cs_net_paid_inc_ship DESC) AS carrier_rank,
  CASE WHEN j.cs_quantity > 10 THEN 'Large' ELSE 'Small' END AS order_size,
  ROW_NUMBER() OVER (ORDER BY j.cs_net_paid_inc_ship DESC) AS overall_seq
FROM joined j
WHERE j.cs_order_number IN (SELECT cs_order_number FROM intersected_orders)   -- keep only intersected orders
ORDER BY carrier_rank, net_paid_inc_ship DESC
LIMIT 100
