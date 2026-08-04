WITH inv_agg AS (
  SELECT inv_item_sk,
         inv_warehouse_sk,
         sum(inv_quantity_on_hand) AS total_on_hand
  FROM inventory
  GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
  d.d_year,
  i.i_item_id,
  i.i_manufact,
  s.s_store_name,
  cc.cc_name,
  sm.sm_type,
  w.w_warehouse_name,
  cr.cr_return_amount,
  inv_agg.total_on_hand,
  (SELECT sum(inv_quantity_on_hand) FROM inventory inv_sub WHERE inv_sub.inv_item_sk = i.i_item_sk) AS item_inventory_total,
  (SELECT count(*) FROM catalog_returns cr_sub WHERE cr_sub.cr_item_sk = i.i_item_sk) AS catalog_return_cnt
FROM
  date_dim d
  JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
  FULL OUTER JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  JOIN (
    SELECT * FROM item TABLESAMPLE BERNOULLI (10)
  ) i
    ON sr.sr_item_sk = i.i_item_sk
  JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
  LEFT JOIN inv_agg
    ON i.i_item_sk = inv_agg.inv_item_sk
  LEFT JOIN warehouse w
    ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_item_sk = i.i_item_sk
  LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_item_sk = i.i_item_sk
  LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
  d.d_year = 1998
  AND i.i_manufact = 'antin stn st'
  AND sm.sm_type = 'AIR'
  AND s.s_state = 'CA'
  AND cc.cc_gmt_offset > 0
  AND t.t_am_pm = 'PM'
  AND EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_return_amount > 100
      )
GROUP BY
  d.d_year,
  i.i_item_id,
  i.i_manufact,
  s.s_store_name,
  cc.cc_name,
  sm.sm_type,
  w.w_warehouse_name,
  cr.cr_return_amount,
  inv_agg.total_on_hand,
  i.i_item_sk
HAVING
  sum(cr.cr_return_amount) > 500
ORDER BY
  d.d_year DESC,
  total_on_hand DESC
LIMIT 100
