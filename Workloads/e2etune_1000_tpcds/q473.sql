WITH address_stats AS (
  SELECT ca_state,
         COUNT(*) AS address_cnt,
         AVG(ca_gmt_offset) AS avg_gmt_offset,
         COUNT(DISTINCT ca_county) AS distinct_counties
  FROM customer_address
  WHERE ca_location_type = 'single family'
  GROUP BY ca_state
),
item_stats AS (
  SELECT i_brand,
         i_category,
         COUNT(*) AS item_cnt,
         AVG(i_current_price) AS avg_price,
         SUM(i_wholesale_cost) AS total_wholesale,
         MIN(i_rec_start_date) AS earliest_start
  FROM item
  WHERE i_current_price > 10
    AND i_rec_end_date IS NULL
  GROUP BY i_brand, i_category
)
SELECT a.ca_state,
       a.address_cnt,
       a.avg_gmt_offset,
       a.distinct_counties,
       i.i_brand,
       i.i_category,
       i.item_cnt,
       i.avg_price,
       i.total_wholesale,
       ROW_NUMBER() OVER (PARTITION BY a.ca_state ORDER BY i.avg_price DESC) AS brand_rank_in_state
FROM address_stats a
JOIN item_stats i
  ON substring(a.ca_state, 1, 2) = substring(i.i_brand, 1, 2)
WHERE a.address_cnt > 5
ORDER BY a.ca_state, brand_rank_in_state
LIMIT 100
