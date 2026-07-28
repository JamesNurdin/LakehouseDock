WITH joined AS (
    SELECT
        sr.sr_returned_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        st.s_store_sk,
        st.s_store_name,
        st.s_state,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_fee,
        CASE
            WHEN sr.sr_return_amt > 1000 THEN 'HIGH'
            WHEN sr.sr_return_amt BETWEEN 500 AND 1000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS return_category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002                -- predicate 1
      AND st.s_state IN ('CA', 'TX', 'NY')              -- predicate 2
      AND cd.cd_gender = 'M'                           -- predicate 3
      AND sr.sr_return_quantity >= 30                  -- predicate 4
      AND sr.sr_fee < 60
),
inner_agg AS (
    SELECT
        d_year,
        s_state,
        s_store_name,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_quantity) AS avg_return_qty,
        SUM(CASE WHEN return_category = 'HIGH' THEN 1 ELSE 0 END) AS high_return_cnt
    FROM joined j
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = j.c_customer_sk
          AND sr2.sr_return_quantity > 50
    )
    GROUP BY ROLLUP (d_year, s_state, s_store_name)
)
SELECT
    d_year,
    s_state,
    SUM(total_return_amt) AS sum_return_amt,
    COUNT(DISTINCT s_store_name) AS distinct_store_cnt,
    AVG(avg_return_qty) AS avg_return_qty_per_group
FROM inner_agg
GROUP BY ROLLUP (d_year, s_state)
HAVING SUM(total_return_amt) > 5000
ORDER BY d_year DESC NULLS LAST, s_state
LIMIT 100
