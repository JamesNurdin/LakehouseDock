WITH
  -- Aggregate store returns per customer
  returns_agg AS (
    SELECT
      sr_customer_sk,
      SUM(sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt,
      MAX(sr_return_quantity) AS max_return_qty
    FROM store_returns
    GROUP BY sr_customer_sk
  ),
  -- Sample a fraction of the inventory table
  inventory_sample AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  -- Key set from store_returns
  key_set_a AS (
    SELECT sr_item_sk AS item_sk FROM store_returns
  ),
  -- Key set from web_sales
  key_set_b AS (
    SELECT ws_item_sk AS item_sk FROM web_sales
  ),
  -- Items present in returns but not in sales
  except_items AS (
    SELECT item_sk FROM key_set_a
    EXCEPT
    SELECT item_sk FROM key_set_b
  ),
  -- Items present in both returns and sales
  intersect_items AS (
    SELECT item_sk FROM key_set_a
    INTERSECT
    SELECT item_sk FROM key_set_b
  )
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  ra.total_return_amt,
  ra.return_cnt,
  CASE WHEN ib.ib_upper_bound < 30000 THEN 'Low' ELSE 'High' END AS income_category,
  ws.ws_order_number,
  ws.ws_quantity,
  sr.sr_return_quantity,
  qty_expanded AS expanded_quantity,
  RANK() OVER (PARTITION BY c.c_customer_id ORDER BY ra.total_return_amt DESC) AS return_rank
FROM returns_agg ra
JOIN customer c ON ra.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN inventory_sample inv ON inv.inv_item_sk = i.i_item_sk
JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
CROSS JOIN UNNEST(array[ws.ws_quantity, sr.sr_return_quantity]) AS t(qty_expanded)
WHERE i.i_wholesale_cost > 5
  AND ib.ib_upper_bound < 50000
  AND sr.sr_return_quantity > 5
  AND ws.ws_quantity > 1
  AND td.t_hour BETWEEN 9 AND 17
ORDER BY return_rank
LIMIT 100
