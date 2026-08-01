WITH store_agg AS (
   SELECT
       'Store' AS entity_type,
       s.s_store_name AS entity_name,
       SUM(sr.sr_return_quantity) AS total_return_qty,
       SUM(sr.sr_return_amt) AS total_return_amt
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   WHERE ib.ib_lower_bound >= (SELECT MIN(ib2.ib_lower_bound) FROM income_band ib2 WHERE ib2.ib_upper_bound > 50000)
     AND t.t_hour BETWEEN 9 AND 17
   GROUP BY s.s_store_name
),
item_agg AS (
   SELECT
       'Item' AS entity_type,
       i.i_product_name AS entity_name,
       SUM(sr.sr_return_quantity) AS total_return_qty,
       SUM(sr.sr_return_amt) AS total_return_amt
   FROM store_returns sr
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   WHERE ib.ib_upper_bound <= (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2 WHERE ib2.ib_lower_bound < 200000)
     AND EXISTS (SELECT 1 FROM reason r WHERE r.r_reason_sk = sr.sr_reason_sk AND r.r_reason_desc LIKE '%Damaged%')
     AND t.t_hour BETWEEN 9 AND 17
   GROUP BY i.i_product_name
),
combined AS (
   SELECT entity_type, entity_name, total_return_qty, total_return_amt FROM store_agg
   UNION ALL
   SELECT entity_type, entity_name, total_return_qty, total_return_amt FROM item_agg
)
SELECT
   entity_type,
   entity_name,
   total_return_qty,
   total_return_amt,
   ROW_NUMBER() OVER (PARTITION BY entity_type ORDER BY total_return_amt DESC) AS rank_within_type,
   (SELECT MIN(ib3.ib_lower_bound) FROM income_band ib3 WHERE ib3.ib_upper_bound > 50000) AS min_income_lower_bound
FROM combined
ORDER BY total_return_amt DESC
LIMIT 100
