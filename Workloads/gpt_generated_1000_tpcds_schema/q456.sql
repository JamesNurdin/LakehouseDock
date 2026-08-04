WITH
  full_inv AS (
    SELECT i.inv_warehouse_sk,
           i.inv_quantity_on_hand,
           w.w_warehouse_sk,
           w.w_warehouse_id,
           w.w_street_name,
           w.w_street_type,
           w.w_country,
           w.w_gmt_offset
    FROM inventory i
    FULL OUTER JOIN warehouse w
      ON i.inv_warehouse_sk = w.w_warehouse_sk
  ),
  intersect_warehouses AS (
    SELECT w_warehouse_id FROM warehouse WHERE regexp_like(w_street_name, '.*Rd$')
    INTERSECT
    SELECT w_warehouse_id FROM warehouse WHERE w_street_type = 'Drive'
  ),
  expanded AS (
    SELECT f.w_warehouse_id,
           f.w_country,
           f.inv_quantity_on_hand,
           f.w_street_name,
           f.w_street_type,
           f.w_gmt_offset,
           word
    FROM full_inv f
    CROSS JOIN UNNEST(split(f.w_street_name, ' ')) AS t(word)
  ),
  agg AS (
    SELECT e.w_warehouse_id,
           e.w_country,
           SUM(e.inv_quantity_on_hand) AS total_qty,
           AVG(e.inv_quantity_on_hand) AS avg_qty,
           COUNT(DISTINCT e.word) AS distinct_word_cnt,
           CONCAT(e.w_street_name, ' ', e.w_street_type) AS full_street,
           REGEXP_EXTRACT(e.w_street_name, '([A-Za-z]+)', 1) AS first_word,
           e.w_gmt_offset
    FROM expanded e
    WHERE e.w_gmt_offset > (SELECT MAX(p_cost) FROM promotion)
      AND e.w_warehouse_id IN (SELECT w_warehouse_id FROM intersect_warehouses)
      AND e.w_street_name LIKE '%Laurel%'
    GROUP BY e.w_warehouse_id,
             e.w_country,
             e.w_street_name,
             e.w_street_type,
             e.w_gmt_offset
  )
SELECT a.w_warehouse_id,
       a.w_country,
       a.total_qty,
       a.avg_qty,
       a.distinct_word_cnt,
       a.full_street,
       a.first_word,
       ROW_NUMBER() OVER (PARTITION BY a.w_country ORDER BY a.total_qty DESC) AS qty_rank
FROM agg a
ORDER BY a.total_qty DESC
LIMIT 100
