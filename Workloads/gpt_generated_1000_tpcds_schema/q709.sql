WITH
  store_info AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      s.s_gmt_offset,
      s.s_floor_space,
      d.d_year,
      d.d_week_seq,
      ARRAY[ s.s_city, s.s_state ] AS location_arr
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_state = 'CA'
      AND d.d_year = 2000
      AND s.s_floor_space > 1500
  ),

  call_center_info AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_state,
      cc.cc_employees,
      cc.cc_gmt_offset,
      d.d_year,
      d.d_week_seq,
      h.hour_cnt,
      split(cc.cc_hours, ',') AS hours_arr
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
      SELECT COUNT(*) AS hour_cnt
      FROM UNNEST(split(cc.cc_hours, ',')) AS t(hour)
    ) h
    WHERE cc.cc_state = 'CA'
      AND d.d_year = 2000
      AND cc.cc_employees > 30
  ),

  promo_info AS (
    SELECT
      p.p_promo_sk,
      p.p_promo_name,
      p.p_cost,
      p.p_response_target,
      p.p_discount_active,
      d_start.d_year AS start_year,
      d_end.d_year AS end_year
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON p.p_end_date_sk   = d_end.d_date_sk
    WHERE p.p_channel_tv = 'N'
      AND p.p_channel_dmail = 'Y'
      AND d_start.d_year = 2000
  ),

  intersect_years AS (
    SELECT d_year FROM store_info
    INTERSECT
    SELECT d_year FROM call_center_info
  ),

  promo_years AS (
    SELECT start_year AS d_year FROM promo_info
  ),

  common_years AS (
    SELECT d_year FROM intersect_years
    INTERSECT
    SELECT d_year FROM promo_years
  ),

  union_agg AS (
    SELECT
      s.s_store_sk AS entity_id,
      'store'       AS entity_type,
      s.s_gmt_offset AS gmt_offset,
      SUM(s.s_floor_space) AS metric_sum,
      COUNT(*) AS row_cnt
    FROM store_info s
    GROUP BY s.s_store_sk, s.s_gmt_offset
    UNION
    SELECT
      cc.cc_call_center_sk AS entity_id,
      'call_center'       AS entity_type,
      cc.cc_gmt_offset    AS gmt_offset,
      SUM(cc.cc_employees) AS metric_sum,
      COUNT(*) AS row_cnt
    FROM call_center_info cc
    GROUP BY cc.cc_call_center_sk, cc.cc_gmt_offset
  )
SELECT
  ua.entity_type,
  COUNT(DISTINCT ua.entity_id)               AS distinct_entities,
  SUM(ua.metric_sum)                         AS total_metric,
  AVG(ua.gmt_offset)                         AS avg_gmt_offset,
  CASE WHEN SUM(ua.metric_sum) > 5000 THEN 'HIGH' ELSE 'LOW' END AS size_category,
  loc.city,
  loc.state
FROM union_agg ua
JOIN (
  SELECT s.s_store_sk, s.s_city AS city, s.s_state AS state
  FROM store s
  WHERE s.s_state = 'CA'
) loc ON ua.entity_id = loc.s_store_sk
WHERE ua.entity_type = 'store'
  AND EXISTS (SELECT 1 FROM common_years cy WHERE cy.d_year = 2000)
GROUP BY ua.entity_type, loc.city, loc.state
ORDER BY total_metric DESC
LIMIT 10
