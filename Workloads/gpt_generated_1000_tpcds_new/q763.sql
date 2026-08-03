WITH
  store_ret AS (
    SELECT
      sr.sr_returned_date_sk AS date_sk,
      sr.sr_return_time_sk   AS time_sk,
      sr.sr_item_sk          AS item_sk,
      sr.sr_store_sk         AS store_sk,
      sr.sr_reason_sk        AS reason_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      d.d_date,
      s.s_store_name,
      r.r_reason_desc       AS reason_desc_store
    FROM store_returns sr
    JOIN date_dim d      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s         ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r       ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_state = 'CA'
  ),
  catalog_ret AS (
    SELECT
      cr.cr_returned_date_sk AS date_sk,
      cr.cr_returned_time_sk AS time_sk,
      cr.cr_item_sk          AS item_sk,
      cr.cr_warehouse_sk     AS warehouse_sk,
      cr.cr_reason_sk        AS reason_sk,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      d.d_date,
      w.w_warehouse_name,
      r.r_reason_desc       AS reason_desc_catalog
    FROM catalog_returns cr
    JOIN date_dim d    ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w   ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r     ON cr.cr_reason_sk = r.r_reason_sk
    WHERE w.w_state = 'CA'
  ),
  full_joined AS (
    SELECT
      COALESCE(sr.date_sk, cr.date_sk)               AS date_sk,
      COALESCE(sr.time_sk, cr.time_sk)               AS time_sk,
      COALESCE(sr.item_sk, cr.item_sk)               AS item_sk,
      COALESCE(sr.reason_sk, cr.reason_sk)           AS reason_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      sr.s_store_name,
      cr.w_warehouse_name,
      sr.reason_desc_store,
      cr.reason_desc_catalog
    FROM store_ret sr
    FULL OUTER JOIN catalog_ret cr
      ON sr.date_sk   = cr.date_sk
     AND sr.item_sk   = cr.item_sk
     AND sr.reason_sk = cr.reason_sk
  ),
  anti_joined AS (
    SELECT fj.*
    FROM full_joined fj
    WHERE NOT EXISTS (
      SELECT 1
      FROM inventory i
      WHERE i.inv_date_sk = fj.date_sk
        AND i.inv_item_sk = fj.item_sk
    )
  ),
  intersect_items AS (
    SELECT item_sk FROM store_ret
    INTERSECT
    SELECT item_sk FROM catalog_ret
  ),
  final AS (
    SELECT
      aj.date_sk,
      d.d_date,
      aj.item_sk,
      aj.reason_sk,
      COALESCE(aj.reason_desc_store, aj.reason_desc_catalog) AS reason_desc,
      aj.s_store_name,
      aj.w_warehouse_name,
      aj.cr_return_amount,
      aj.sr_return_amt,
      inv_sum.total_qty AS total_inventory_qty,
      (
        SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = aj.item_sk
      ) AS total_store_returns
    FROM anti_joined aj
    LEFT JOIN date_dim d ON aj.date_sk = d.d_date_sk
    LEFT JOIN LATERAL (
      SELECT SUM(i.inv_quantity_on_hand) AS total_qty
      FROM inventory i
      WHERE i.inv_date_sk = aj.date_sk
        AND i.inv_item_sk = aj.item_sk
    ) AS inv_sum ON TRUE
    WHERE aj.item_sk IN (SELECT item_sk FROM intersect_items)
  )
SELECT
  date_sk,
  d_date,
  item_sk,
  reason_sk,
  reason_desc,
  s_store_name,
  w_warehouse_name,
  cr_return_amount,
  sr_return_amt,
  total_inventory_qty,
  total_store_returns
FROM final
ORDER BY d_date DESC, item_sk
LIMIT 100
