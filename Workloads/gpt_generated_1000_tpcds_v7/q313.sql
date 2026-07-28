WITH
  store_agg AS (
    SELECT
      'store' AS source,
      s.s_store_id AS location_id,
      s.s_store_name AS location_name,
      SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t
      ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    WHERE s.s_state = 'CA'
      AND i.i_brand = 'BrandX'
    GROUP BY s.s_store_id, s.s_store_name
  ),
  callcenter_agg AS (
    SELECT
      'call_center' AS source,
      c.cc_call_center_id AS location_id,
      c.cc_name AS location_name,
      SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN call_center c
      ON cr.cr_call_center_sk = c.cc_call_center_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_code = 'AIR'
      AND i.i_category = 'Electronics'
    GROUP BY c.cc_call_center_id, c.cc_name
  )
SELECT source,
       location_id,
       location_name,
       total_net_loss
FROM   store_agg
UNION ALL
SELECT source,
       location_id,
       location_name,
       total_net_loss
FROM   callcenter_agg
ORDER BY total_net_loss DESC
