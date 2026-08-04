WITH
  sales_agg AS (
    SELECT
      s.s_store_id,
      s.s_store_name,
      concat(s.s_city, ', ', s.s_state) AS store_location,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2002
      AND regexp_like(i.i_item_desc, '[A-Z]{3}')
      AND s.s_manager LIKE '%Jacob%'
    GROUP BY s.s_store_id, s.s_store_name, s.s_city, s.s_state
  ),
  returns_set AS (
    SELECT DISTINCT s.s_store_id
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{3}')
  ),
  filtered_sales AS (
    SELECT *
    FROM sales_agg
    EXCEPT
    SELECT s.s_store_id, s.s_store_name, s.store_location, s.total_profit, s.sales_cnt
    FROM sales_agg s
    JOIN returns_set r ON s.s_store_id = r.s_store_id
  )
SELECT
  f.s_store_id,
  f.s_store_name,
  f.store_location,
  f.total_profit,
  f.sales_cnt,
  substring(f.s_store_name FROM 1 FOR 10) AS short_name,
  regexp_extract(f.store_location, ',\\s*(\\w{2})$', 1) AS state_code
FROM filtered_sales f
ORDER BY f.total_profit DESC
LIMIT 100
