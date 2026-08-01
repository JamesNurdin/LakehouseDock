WITH
  base AS (
    SELECT
      s.s_store_id,
      d.d_date,
      SUM(wr.wr_return_amt)            AS total_return_amt,
      COUNT(wr.wr_return_quantity)     AS total_return_qty,
      SUM(wr.wr_return_tax)            AS total_return_tax,
      hd_ret.hd_buy_potential           AS ret_buy_potential,
      hd_ref.hd_buy_potential           AS ref_buy_potential,
      cc.cc_name                        AS call_center_name,
      p.p_promo_name                    AS promo_name
    FROM store s
    FULL OUTER JOIN date_dim d
      ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN household_demographics hd_ret
      ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    LEFT JOIN household_demographics hd_ref
      ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    LEFT JOIN call_center cc
      ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN (
      SELECT * FROM promotion TABLESAMPLE BERNOULLI (5)
    ) p
      ON p.p_start_date_sk = d.d_date_sk
    WHERE s.s_state = 'TN'
      AND d.d_year = 2001
      AND s.s_gmt_offset > (SELECT AVG(s2.s_gmt_offset) FROM store s2)
      AND s.s_zip LIKE '37%'
      AND cc.cc_tax_percentage IS NOT NULL
    GROUP BY
      s.s_store_id,
      d.d_date,
      hd_ret.hd_buy_potential,
      hd_ref.hd_buy_potential,
      cc.cc_name,
      p.p_promo_name
  ),
  agg1 AS (
    SELECT
      s_store_id               AS store_id,
      AVG(total_return_amt)    AS avg_return_amt,
      SUM(total_return_qty)    AS sum_qty,
      ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY AVG(total_return_amt) DESC) AS rn
    FROM base
    GROUP BY s_store_id
    HAVING AVG(total_return_amt) > 500
  ),
  final1 AS (
    SELECT
      a.store_id,
      a.avg_return_amt,
      a.sum_qty,
      a.rn,
      (
        SELECT MAX(b.total_return_amt)
        FROM base b
        WHERE b.s_store_id = a.store_id
          AND b.total_return_tax > 0
      ) AS max_return_amt_for_store
    FROM agg1 a
    WHERE a.rn <= 10
  ),
  promo_agg AS (
    SELECT
      p.p_promo_name          AS promo_key,
      COUNT(*)                AS promo_cnt,
      SUM(p.p_cost)           AS total_cost,
      ROW_NUMBER() OVER (ORDER BY SUM(p.p_cost) DESC) AS promo_rn
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
      AND p.p_cost > (SELECT AVG(p2.p_cost) FROM promotion p2)
    GROUP BY p.p_promo_name
    HAVING COUNT(*) > 5
  )
SELECT
  q.store_id,
  q.avg_return_amt,
  q.sum_qty,
  q.max_return_amt_for_store,
  q.rn
FROM (
  SELECT
    f.store_id,
    f.avg_return_amt,
    f.sum_qty,
    f.max_return_amt_for_store,
    f.rn
  FROM final1 f
  UNION DISTINCT
  SELECT
    pa.promo_key        AS store_id,
    pa.total_cost       AS avg_return_amt,
    pa.promo_cnt        AS sum_qty,
    CAST(NULL AS decimal(15,2)) AS max_return_amt_for_store,
    pa.promo_rn         AS rn
  FROM promo_agg pa
) q
ORDER BY q.avg_return_amt DESC
LIMIT 100
