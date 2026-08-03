WITH
agg_catalog AS (
    SELECT
        cr.cr_warehouse_sk AS wh_sk,
        cr.cr_reason_sk AS r_sk,
        SUM(cr.cr_return_amount) AS cat_return_amt,
        MAX(cr.cr_returned_time_sk) AS max_time_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 200
    GROUP BY cr.cr_warehouse_sk, cr.cr_reason_sk
),
agg_store AS (
    SELECT
        sr.sr_store_sk AS wh_sk,
        sr.sr_reason_sk AS r_sk,
        SUM(sr.sr_return_amt) AS store_return_amt,
        MAX(sr.sr_return_time_sk) AS max_time_sk
    FROM store_returns sr
    WHERE sr.sr_return_amt > 200
    GROUP BY sr.sr_store_sk, sr.sr_reason_sk
),
full_join AS (
    SELECT
        COALESCE(a.wh_sk, s.wh_sk) AS wh_sk,
        COALESCE(a.r_sk, s.r_sk) AS r_sk,
        a.cat_return_amt,
        s.store_return_amt,
        COALESCE(a.max_time_sk, s.max_time_sk) AS max_time_sk
    FROM agg_catalog a
    FULL OUTER JOIN agg_store s
        ON a.wh_sk = s.wh_sk AND a.r_sk = s.r_sk
),
key_intersect AS (
    SELECT
        fj.wh_sk,
        fj.r_sk
    FROM full_join fj
    WHERE fj.cat_return_amt IS NOT NULL
      AND EXISTS (
          SELECT 1
          FROM reason r
          WHERE r.r_reason_sk = fj.r_sk
            AND r.r_reason_desc LIKE '%damaged%'
      )
      AND EXISTS (
          SELECT 1
          FROM warehouse w
          WHERE w.w_warehouse_sk = fj.wh_sk
            AND w.w_city = 'New York'
      )
    INTERSECT
    SELECT
        fj.wh_sk,
        fj.r_sk
    FROM full_join fj
    WHERE fj.store_return_amt IS NOT NULL
      AND EXISTS (
          SELECT 1
          FROM reason r
          WHERE r.r_reason_sk = fj.r_sk
            AND r.r_reason_desc LIKE '%damaged%'
      )
      AND EXISTS (
          SELECT 1
          FROM time_dim t
          JOIN reason r ON r.r_reason_sk = fj.r_sk
          WHERE t.t_time_sk = fj.max_time_sk
            AND t.t_hour BETWEEN 9 AND 17
      )
)
SELECT
    ki.wh_sk,
    ki.r_sk,
    f.cat_return_amt,
    f.store_return_amt
FROM key_intersect ki
JOIN full_join f
  ON f.wh_sk = ki.wh_sk AND f.r_sk = ki.r_sk
ORDER BY ki.wh_sk, ki.r_sk
LIMIT 100
