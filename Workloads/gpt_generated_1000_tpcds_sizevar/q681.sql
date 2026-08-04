WITH
  cr_agg AS (
    SELECT
      cr_call_center_sk,
      cr_reason_sk,
      SUM(cr_return_amount)               AS total_return_amount,
      AVG(cr_return_tax)                  AS avg_return_tax,
      COUNT(*)                           AS cnt_returns,
      MIN(cr_return_quantity)            AS min_qty,
      MAX(cr_return_quantity)            AS max_qty
    FROM catalog_returns
    WHERE cr_return_amount        > 100
      AND cr_return_tax           BETWEEN 5 AND 200
      AND cr_store_credit         > 20
      AND cr_refunded_cash        < 5000
      AND cr_reversed_charge      <> 0
    GROUP BY cr_call_center_sk, cr_reason_sk
  ),
  filtered_cc AS (
    SELECT *
    FROM call_center
    WHERE cc_mkt_id      IN (2, 4, 5)
      AND cc_state        = 'CA'
      AND cc_gmt_offset   BETWEEN -5 AND 0
      AND cc_rec_end_date = DATE '2001-12-31'
      AND cc_tax_percentage < 5
      AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_call_center_sk = call_center.cc_call_center_sk
              AND cr2.cr_return_quantity > 5
          )
  ),
  reason_filtered AS (
    SELECT *
    FROM reason
    WHERE r_reason_desc LIKE '%working%'
       OR r_reason_desc LIKE '%warranty%'
  ),
  unioned AS (
    SELECT
      cr_agg.cr_call_center_sk,
      cr_agg.cr_reason_sk,
      cr_agg.total_return_amount,
      cr_agg.cnt_returns,
      CASE WHEN cr_agg.total_return_amount > 1000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM cr_agg
    UNION DISTINCT
    SELECT
      cr_agg.cr_call_center_sk,
      cr_agg.cr_reason_sk,
      cr_agg.total_return_amount,
      cr_agg.cnt_returns,
      CASE WHEN cr_agg.total_return_amount > 1000 THEN 'HIGH' ELSE 'LOW' END
    FROM cr_agg
    WHERE cr_agg.cnt_returns > 10
  ),
  set_a AS (
    SELECT
      fc.cc_call_center_id,
      r.r_reason_desc,
      u.amount_category,
      SUM(u.total_return_amount) AS sum_return_amount,
      COUNT(*)                  AS call_cnt
    FROM unioned u
    JOIN filtered_cc fc   ON u.cr_call_center_sk = fc.cc_call_center_sk
    JOIN reason_filtered r ON u.cr_reason_sk    = r.r_reason_sk
    GROUP BY fc.cc_call_center_id, r.r_reason_desc, u.amount_category
  ),
  set_b AS (
    SELECT
      fc.cc_call_center_id,
      r.r_reason_desc,
      u.amount_category,
      SUM(u.total_return_amount) AS sum_return_amount,
      COUNT(*)                  AS call_cnt
    FROM unioned u
    JOIN filtered_cc fc   ON u.cr_call_center_sk = fc.cc_call_center_sk
    JOIN reason_filtered r ON u.cr_reason_sk    = r.r_reason_sk
    WHERE u.amount_category = 'LOW'
    GROUP BY fc.cc_call_center_id, r.r_reason_desc, u.amount_category
  )
SELECT *
FROM (
      SELECT * FROM set_a
      UNION DISTINCT
      SELECT * FROM set_b
) combined
EXCEPT
SELECT *
FROM set_b
WHERE sum_return_amount < 500
ORDER BY sum_return_amount DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
