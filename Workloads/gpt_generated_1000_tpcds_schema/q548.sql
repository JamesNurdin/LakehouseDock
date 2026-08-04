WITH
  inv_agg AS (
    SELECT
      inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_qty,
      COUNT(*) AS item_cnt
    FROM inventory
    GROUP BY inv_date_sk
  ),
  store_address AS (
    SELECT
      s.s_store_sk,
      s.s_store_id,
      t.addr_elem AS address_part
    FROM store s
    CROSS JOIN UNNEST(ARRAY[s.s_street_type, s.s_street_name]) AS t(addr_elem)
  ),
  intersect_stores AS (
    SELECT s.s_store_id
    FROM store s
    WHERE s.s_state = 'CA'
    INTERSECT
    SELECT s.s_store_id
    FROM store s
    WHERE s.s_market_desc LIKE '%Financial%'
  )
SELECT
  s.s_store_id,
  d.d_date,
  cp.cp_catalog_number,
  hd.hd_buy_potential,
  CASE WHEN hd.hd_vehicle_count < 0 THEN 0 ELSE hd.hd_vehicle_count END AS vehicle_cnt_adj,
  inv_agg.total_qty,
  inv_agg.item_cnt,
  RANK() OVER (PARTITION BY s.s_state ORDER BY inv_agg.total_qty DESC) AS qty_state_rank,
  (SELECT COUNT(*) FROM customer c WHERE c.c_preferred_cust_flag = 'Y') AS pref_cust_cnt,
  addr.address_part
FROM inv_agg
JOIN date_dim d ON inv_agg.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN store_address addr ON addr.s_store_sk = s.s_store_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
JOIN customer c ON c.c_first_sales_date_sk = d.d_date_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND s.s_market_desc LIKE '%Financial%'
  AND hd.hd_buy_potential = '>10000'
  AND inv_agg.total_qty > 500
  AND c.c_email_address LIKE '%@be.org%'
  AND s.s_store_id IN (SELECT s_store_id FROM intersect_stores)
UNION DISTINCT
SELECT
  s2.s_store_id,
  d2.d_date,
  cp2.cp_catalog_number,
  hd2.hd_buy_potential,
  CASE WHEN hd2.hd_vehicle_count < 0 THEN 0 ELSE hd2.hd_vehicle_count END AS vehicle_cnt_adj,
  inv_agg2.total_qty,
  inv_agg2.item_cnt,
  RANK() OVER (PARTITION BY s2.s_state ORDER BY inv_agg2.total_qty DESC) AS qty_state_rank,
  (SELECT COUNT(*) FROM customer c2 WHERE c2.c_preferred_cust_flag = 'Y') AS pref_cust_cnt,
  addr2.address_part
FROM inv_agg AS inv_agg2
JOIN date_dim d2 ON inv_agg2.inv_date_sk = d2.d_date_sk
JOIN store s2 ON s2.s_closed_date_sk = d2.d_date_sk
JOIN store_address addr2 ON addr2.s_store_sk = s2.s_store_sk
JOIN catalog_page cp2 ON cp2.cp_end_date_sk = d2.d_date_sk
JOIN customer c2 ON c2.c_first_sales_date_sk = d2.d_date_sk
JOIN household_demographics hd2 ON c2.c_current_hdemo_sk = hd2.hd_demo_sk
WHERE d2.d_year = 2002
  AND s2.s_state = 'NY'
  AND s2.s_market_desc LIKE '%Events%'
  AND hd2.hd_buy_potential = '500-1000'
  AND inv_agg2.total_qty > 400
  AND c2.c_email_address LIKE '%@DBXgl18FGo.edu%'
ORDER BY qty_state_rank, s_store_id
LIMIT 100
