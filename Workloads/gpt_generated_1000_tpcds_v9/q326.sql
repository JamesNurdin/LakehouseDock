WITH filtered_store AS (
   SELECT
      s.s_store_sk,
      s.s_store_id,
      s.s_manager,
      s.s_number_employees,
      s.s_floor_space,
      s.s_market_id,
      s.s_closed_date_sk
   FROM store s
   WHERE s.s_manager = 'John Mccoy'
     AND s.s_street_name LIKE '%Park%'
     AND s.s_street_type = 'Lane'
     AND s.s_number_employees >= 50
     AND s.s_floor_space IS NOT NULL
),
joined AS (
   SELECT
      fs.s_store_sk,
      fs.s_store_id,
      fs.s_manager,
      fs.s_number_employees,
      fs.s_floor_space,
      fs.s_market_id,
      d.d_quarter_seq,
      d.d_current_week,
      d.d_dom,
      d.d_year
   FROM filtered_store fs
   JOIN date_dim d
     ON fs.s_closed_date_sk = d.d_date_sk
   WHERE d.d_quarter_seq IN (8, 12, 18)
     AND d.d_current_week = 'N'
     AND d.d_dom BETWEEN 1 AND 20
),
agg_main AS (
   SELECT
      j.s_market_id,
      j.d_quarter_seq,
      COUNT(DISTINCT j.s_store_sk) AS store_cnt,
      SUM(j.s_floor_space) AS total_floor_space,
      AVG(j.s_number_employees) AS avg_employees,
      MIN(j.s_floor_space) AS min_floor_space,
      MAX(j.s_floor_space) AS max_floor_space
   FROM joined j
   GROUP BY GROUPING SETS (
      (j.s_market_id, j.d_quarter_seq),
      (j.s_market_id),
      ()
   )
),
agg_with_window AS (
   SELECT
      a.*,
      RANK() OVER (PARTITION BY a.s_market_id ORDER BY a.total_floor_space DESC) AS floor_space_rank,
      SUM(a.total_floor_space) OVER (PARTITION BY a.s_market_id) AS market_total_floor_space
   FROM agg_main a
)
SELECT
   aw.s_market_id,
   aw.d_quarter_seq,
   aw.store_cnt,
   aw.total_floor_space,
   aw.avg_employees,
   aw.min_floor_space,
   aw.max_floor_space,
   aw.floor_space_rank,
   aw.market_total_floor_space,
   (SELECT MAX(s_floor_space) FROM store) AS overall_max_floor_space
FROM agg_with_window aw

UNION

SELECT
   aw.s_market_id,
   aw.d_quarter_seq,
   aw.store_cnt,
   aw.total_floor_space,
   aw.avg_employees,
   aw.min_floor_space,
   aw.max_floor_space,
   aw.floor_space_rank,
   aw.market_total_floor_space,
   (SELECT MAX(s_floor_space) FROM store) AS overall_max_floor_space
FROM agg_with_window aw
WHERE EXISTS (
   SELECT 1
   FROM store s2
   WHERE s2.s_market_id = aw.s_market_id
     AND s2.s_manager = 'David Thomas'
)
LIMIT 100
