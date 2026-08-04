WITH
  sr_agg AS (
    SELECT
      sr.sr_store_sk,
      sr.sr_reason_sk,
      SUM(sr.sr_return_quantity) AS total_qty
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%damage%'
    GROUP BY sr.sr_store_sk, sr.sr_reason_sk
    HAVING SUM(sr.sr_return_quantity) > 10
  ),
  cr_agg AS (
    SELECT
      cr.cr_call_center_sk,
      cr.cr_reason_sk,
      SUM(cr.cr_return_quantity) AS total_qty
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%damage%'
      AND regexp_like(cc.cc_name, '^.*Center$')
    GROUP BY cr.cr_call_center_sk, cr.cr_reason_sk
    HAVING SUM(cr.cr_return_quantity) > 5
  ),
  full_join AS (
    SELECT
      COALESCE(sr.sr_store_sk, cr.cr_call_center_sk) AS entity_id,
      COALESCE(sr.sr_reason_sk, cr.cr_reason_sk) AS reason_sk,
      COALESCE(sr.total_qty, 0) + COALESCE(cr.total_qty, 0) AS total_qty
    FROM sr_agg sr
    FULL OUTER JOIN cr_agg cr
      ON sr.sr_reason_sk = cr.cr_reason_sk
  ),
  web_agg AS (
    SELECT
      ws.wr_returning_addr_sk AS entity_id,
      SUM(ws.wr_return_quantity) AS total_qty
    FROM web_returns ws
    JOIN reason r ON ws.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%damage%'
    GROUP BY ws.wr_returning_addr_sk
    HAVING SUM(ws.wr_return_quantity) > 8
  ),
  union_set AS (
    SELECT entity_id, total_qty FROM full_join
    UNION
    SELECT entity_id, total_qty FROM web_agg
  ),
  item_match AS (
    SELECT i.i_item_sk AS entity_id
    FROM item i
    WHERE regexp_like(i.i_item_desc, '[A-Z]{3}')
      AND substring(i.i_item_desc, 1, 5) = 'Ultra'
      AND concat(i.i_brand, ' ', i.i_color) LIKE '%Red%'
  ),
  intersect_set AS (
    SELECT us.entity_id, us.total_qty
    FROM union_set us
    INTERSECT
    SELECT im.entity_id, NULL AS total_qty
    FROM item_match im
  )
SELECT entity_id, total_qty
FROM intersect_set
ORDER BY total_qty DESC
