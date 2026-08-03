WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_first_sales_date_sk,
        cd.cd_gender,
        cd.cd_dep_count,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sr.sr_store_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
    FULL OUTER JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd.cd_dep_count > 2
      AND cd.cd_marital_status = 'M'
      AND ib.ib_upper_bound BETWEEN 50000 AND 100000
      AND sr.sr_return_quantity > 5
      AND EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_store_sk = sr.sr_store_sk
              AND sr2.sr_return_quantity > 10
      )
),
agg1 AS (
    SELECT
        cd_gender,
        ib_lower_bound,
        COUNT(DISTINCT sr_store_sk) AS distinct_store_cnt,
        SUM(DISTINCT sr_return_amt) AS distinct_return_sum,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS ret_cnt
    FROM base
    GROUP BY cd_gender, ib_lower_bound
    HAVING SUM(sr_return_amt) > 1000
)
SELECT
    cd_gender,
    ib_lower_bound,
    distinct_store_cnt,
    distinct_return_sum,
    total_return_amt,
    total_net_loss,
    ret_cnt
FROM agg1
WHERE distinct_store_cnt > 1
UNION
SELECT
    cd_gender,
    ib_lower_bound,
    distinct_store_cnt,
    distinct_return_sum,
    total_return_amt,
    total_net_loss,
    ret_cnt
FROM agg1
WHERE total_net_loss < 0
ORDER BY cd_gender, ib_lower_bound
LIMIT 100
