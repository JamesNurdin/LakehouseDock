WITH
    agg_ret AS (
        SELECT
            sr_store_sk,
            sr_cdemo_sk,
            sr_returned_date_sk,
            SUM(sr_return_amt) AS sum_return_amt,
            COUNT(DISTINCT sr_ticket_number) AS cnt_dist_ticket,
            SUM(DISTINCT sr_return_amt) AS sum_dist_return_amt
        FROM store_returns
        WHERE sr_return_ship_cost > 20
          AND sr_returned_date_sk BETWEEN 2451950 AND 2452350
          AND sr_return_quantity >= 1
        GROUP BY sr_store_sk, sr_cdemo_sk, sr_returned_date_sk
    ),
    demo_filt AS (
        SELECT
            cd_demo_sk,
            cd_gender,
            cd_credit_rating,
            cd_dep_count,
            cd_dep_college_count
        FROM customer_demographics
        WHERE cd_credit_rating IN ('Low Risk', 'High Risk')
          AND cd_dep_count > 1
          AND cd_dep_college_count <= 2
    ),
    full_join AS (
        SELECT
            agg.sr_store_sk,
            agg.sr_cdemo_sk,
            agg.sr_returned_date_sk,
            agg.sum_return_amt,
            agg.cnt_dist_ticket,
            agg.sum_dist_return_amt,
            demo.cd_gender,
            demo.cd_credit_rating,
            demo.cd_dep_count,
            demo.cd_dep_college_count
        FROM agg_ret agg
        FULL OUTER JOIN demo_filt demo
            ON agg.sr_cdemo_sk = demo.cd_demo_sk
    ),
    avg_ret AS (
        SELECT
            sr_store_sk,
            AVG(sr_return_amt) AS avg_return_amt
        FROM store_returns
        GROUP BY sr_store_sk
    ),
    joined AS (
        SELECT
            fj.sr_store_sk,
            fj.sr_cdemo_sk,
            fj.sr_returned_date_sk,
            fj.sum_return_amt,
            fj.cnt_dist_ticket,
            fj.sum_dist_return_amt,
            fj.cd_gender,
            fj.cd_credit_rating,
            fj.cd_dep_count,
            fj.cd_dep_college_count,
            ar.avg_return_amt
        FROM full_join fj
        LEFT OUTER JOIN avg_ret ar
            ON fj.sr_store_sk = ar.sr_store_sk
    ),
    unioned AS (
        SELECT
            sr_store_sk,
            cd_credit_rating,
            sum_return_amt,
            cnt_dist_ticket,
            sum_dist_return_amt,
            avg_return_amt
        FROM joined
        WHERE cd_credit_rating IS NOT NULL
        UNION
        SELECT
            sr_store_sk,
            cd_credit_rating,
            sum_return_amt,
            cnt_dist_ticket,
            sum_dist_return_amt,
            avg_return_amt
        FROM joined
        WHERE cd_credit_rating IS NULL
    )
SELECT
    COALESCE(CAST(sr_store_sk AS VARCHAR), 'All Stores') AS store_id,
    COALESCE(cd_credit_rating, 'All Ratings') AS credit_rating,
    SUM(sum_return_amt) AS total_return_amt,
    COUNT(DISTINCT cd_credit_rating) AS distinct_credit_rating_cnt,
    SUM(DISTINCT sum_return_amt) AS sum_of_distinct_return_amt,
    AVG(avg_return_amt) AS overall_avg_return_amt
FROM unioned
WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = unioned.sr_store_sk
          AND sr2.sr_return_amt > 500
    )
GROUP BY GROUPING SETS (
    (sr_store_sk, cd_credit_rating),
    (sr_store_sk),
    (cd_credit_rating),
    ()
)
ORDER BY store_id ASC, credit_rating ASC
OFFSET 0 ROWS FETCH FIRST 20 ROWS ONLY
