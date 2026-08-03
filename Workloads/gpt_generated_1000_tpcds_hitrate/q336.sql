WITH
  base AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_company_name,
      cr.cr_warehouse_sk,
      cr.cr_return_amount,
      cr.cr_net_loss,
      cr.cr_store_credit,
      w.w_warehouse_name,
      w.w_city
    FROM tpcds.call_center cc
    JOIN tpcds.catalog_returns cr
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_country = 'United States'
      AND cr.cr_return_amount > 100
      AND cr.cr_net_loss BETWEEN 50 AND 500
      AND w.w_state = 'CA'
      AND w.w_country = 'United States'
  ),
  agg AS (
    SELECT
      cc_call_center_sk,
      cr_warehouse_sk,
      SUM(cr_return_amount) AS sum_return_amount,
      SUM(cr_net_loss) AS sum_net_loss,
      COUNT(*) AS cnt_returns
    FROM base
    GROUP BY cc_call_center_sk, cr_warehouse_sk
  ),
  filtered_agg AS (
    SELECT *
    FROM agg
    WHERE sum_return_amount > 1000
      AND cnt_returns >= 5
  ),
  intersect_keys AS (
    SELECT cc_call_center_sk FROM filtered_agg WHERE sum_return_amount > 2000
    INTERSECT
    SELECT cc_call_center_sk FROM filtered_agg WHERE cnt_returns > 10
  ),
  final1 AS (
    SELECT
      f.cc_call_center_sk,
      f.cr_warehouse_sk,
      f.sum_return_amount,
      f.sum_net_loss,
      f.cnt_returns,
      (
        SELECT SUM(cr2.cr_return_amount)
        FROM tpcds.catalog_returns cr2
        WHERE cr2.cr_call_center_sk = f.cc_call_center_sk
      ) AS total_return_amount_for_center,
      ls.avg_store_credit
    FROM filtered_agg f
    LEFT JOIN LATERAL (
      SELECT AVG(cr3.cr_store_credit) AS avg_store_credit
      FROM tpcds.catalog_returns cr3
      WHERE cr3.cr_call_center_sk = f.cc_call_center_sk
    ) ls ON TRUE
    WHERE EXISTS (
      SELECT 1
      FROM tpcds.warehouse w2
      WHERE w2.w_warehouse_sk = f.cr_warehouse_sk
        AND w2.w_city IN ('Los Angeles', 'San Francisco')
    )
      AND f.cc_call_center_sk IN (SELECT cc_call_center_sk FROM intersect_keys)
  ),
  final2 AS (
    SELECT
      f.cc_call_center_sk,
      f.cr_warehouse_sk,
      f.sum_return_amount,
      f.sum_net_loss,
      f.cnt_returns,
      (
        SELECT SUM(cr2.cr_return_amount)
        FROM tpcds.catalog_returns cr2
        WHERE cr2.cr_call_center_sk = f.cc_call_center_sk
      ) AS total_return_amount_for_center,
      ls.avg_store_credit
    FROM filtered_agg f
    LEFT JOIN LATERAL (
      SELECT AVG(cr3.cr_store_credit) AS avg_store_credit
      FROM tpcds.catalog_returns cr3
      WHERE cr3.cr_call_center_sk = f.cc_call_center_sk
        AND cr3.cr_warehouse_sk = f.cr_warehouse_sk
    ) ls ON TRUE
    WHERE f.sum_net_loss < 2000
      AND f.cc_call_center_sk IN (SELECT cc_call_center_sk FROM intersect_keys)
  )
SELECT *
FROM (
  SELECT * FROM final1
  UNION DISTINCT
  SELECT * FROM final2
) ordered
ORDER BY sum_return_amount DESC, cc_call_center_sk
LIMIT 100
