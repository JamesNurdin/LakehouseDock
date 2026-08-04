WITH
  intersect_items AS (
    SELECT i.i_item_id
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_sub_shift = 'morning'
    INTERSECT
    SELECT i2.i_item_id
    FROM web_returns wr
    JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
    JOIN time_dim td2 ON wr.wr_returned_time_sk = td2.t_time_sk
    WHERE td2.t_sub_shift = 'night'
  ),
  union_returns AS (
    SELECT
      i.i_item_id,
      cc.cc_name,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*) AS return_cnt,
      i.i_brand_id
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_sub_shift = 'morning'
      AND i.i_brand_id = (SELECT MIN(i2.i_brand_id) FROM item i2)
    GROUP BY i.i_item_id, cc.cc_name, i.i_brand_id
    UNION
    SELECT
      i.i_item_id,
      'Web' AS cc_name,
      SUM(wr.wr_return_amt) AS total_return_amount,
      COUNT(*) AS return_cnt,
      i.i_brand_id
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_sub_shift = 'night'
      AND i.i_brand_id = (SELECT MIN(i2.i_brand_id) FROM item i2)
    GROUP BY i.i_item_id, i.i_brand_id
  )
SELECT
  ur.i_item_id,
  ur.cc_name,
  ur.total_return_amount,
  ur.return_cnt,
  ROW_NUMBER() OVER (ORDER BY ur.total_return_amount DESC) AS rn
FROM union_returns ur
WHERE ur.i_item_id IN (SELECT i_item_id FROM intersect_items)
ORDER BY ur.total_return_amount DESC
LIMIT 100
