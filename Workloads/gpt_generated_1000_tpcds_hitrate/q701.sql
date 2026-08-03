WITH sr_agg AS (
   SELECT sr.sr_store_sk,
          SUM(sr.sr_return_amt) AS total_return_amt,
          COUNT(*) AS return_cnt,
          AVG(sr.sr_return_amt) AS avg_return_amt
   FROM store_returns sr
   WHERE sr.sr_store_sk IN (790, 466, 760)                -- predicate 1
     AND sr.sr_return_quantity > 1                        -- predicate 2
     AND sr.sr_return_amt > 10.0                          -- predicate 3
   GROUP BY sr.sr_store_sk
   HAVING SUM(sr.sr_return_amt) > 100                    -- filter groups
),
right_joined AS (
   SELECT s.s_store_sk,
          s.s_store_name,
          s.s_market_desc,
          s.s_tax_percentage,
          sr_agg.total_return_amt,
          sr_agg.return_cnt,
          sr_agg.avg_return_amt
   FROM store s
   RIGHT OUTER JOIN sr_agg
       ON sr_agg.sr_store_sk = s.s_store_sk               -- fact (sr_agg) to dimension (store)
),
full_joined AS (
   SELECT rj.s_store_sk,
          rj.s_store_name,
          rj.s_market_desc,
          rj.s_tax_percentage,
          rj.total_return_amt,
          rj.return_cnt,
          rj.avg_return_amt,
          s2.s_city,
          s2.s_state
   FROM right_joined rj
   FULL OUTER JOIN store s2
       ON rj.s_store_sk = s2.s_store_sk                  -- keep unmatched rows from both sides
)
SELECT
    f.s_store_sk,
    f.s_store_name,
    f.s_market_desc,
    f.s_tax_percentage,
    f.total_return_amt,
    f.return_cnt,
    f.avg_return_amt,
    f.s_city,
    f.s_state,
    ROW_NUMBER() OVER (PARTITION BY f.s_state ORDER BY f.total_return_amt DESC) AS rn_state,
    RANK() OVER (ORDER BY f.total_return_amt DESC) AS overall_rank,
    CASE
        WHEN f.s_tax_percentage > 0.09 THEN 'HIGH_TAX'
        ELSE 'LOW_TAX'
    END AS tax_category
FROM full_joined f
WHERE f.s_city IS NOT NULL                              -- additional filter predicate
ORDER BY overall_rank, f.s_store_name
LIMIT 100
