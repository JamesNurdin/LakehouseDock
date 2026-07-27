WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_cdemo_sk,
        COUNT(*) AS txn_count,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_unit_price,
        MIN(ss.ss_sales_price) AS min_price,
        MAX(ss.ss_sales_price) AS max_price
    FROM store_sales ss
    WHERE ss.ss_wholesale_cost > 20.00                     -- predicate 1
      AND ss.ss_sales_price BETWEEN 30.00 AND 90.00        -- predicate 2
      AND ss.ss_quantity >= 1                              -- predicate 3
      AND ss.ss_ext_discount_amt < 5.00                    -- predicate 4
      AND ss.ss_ext_tax > 0.00                             -- predicate 5
      AND ss.ss_net_profit > 0.00                          -- predicate 6
    GROUP BY ss.ss_store_sk, ss.ss_cdemo_sk
)
SELECT
    st.s_store_name,
    st.s_city,
    st.s_state,
    agg.txn_count,
    agg.total_sales,
    agg.avg_unit_price,
    agg.min_price,
    agg.max_price
FROM sales_agg agg
JOIN store st
  ON agg.ss_store_sk = st.s_store_sk
WHERE EXISTS (
        SELECT 1
        FROM customer_demographics cd
        WHERE cd.cd_demo_sk = agg.ss_cdemo_sk
          AND cd.cd_gender = 'F'                     -- predicate 7
          AND cd.cd_dep_employed_count >= 2          -- predicate 8
          AND cd.cd_credit_rating = 'Excellent'      -- predicate 9
          AND cd.cd_education_status = 'College'     -- predicate 10
    )
  AND st.s_floor_space > 8000000                     -- predicate 11
  AND st.s_state = 'CA'                               -- predicate 12
  AND st.s_hours LIKE '8AM-%'                         -- predicate 13
  AND st.s_market_id IN (1, 2, 3)                     -- predicate 14
ORDER BY agg.total_sales DESC
LIMIT 100
