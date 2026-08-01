WITH sampled_returns AS (
    SELECT *
    FROM web_returns
    TABLESAMPLE BERNOULLI (10)
),
joined_left AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_return_amt,
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_demo_sk,
        hd.hd_buy_potential
    FROM sampled_returns wr
    LEFT JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_return_amt > 150
      AND cd.cd_education_status = 'College'
      AND hd.hd_buy_potential = '>10000'
),
full_joined AS (
    SELECT
        lj.wr_returned_date_sk,
        lj.wr_return_amt,
        lj.cd_demo_sk,
        lj.hd_demo_sk,
        cd2.cd_demo_sk AS returning_cd_demo_sk,
        hd2.hd_demo_sk AS returning_hd_demo_sk
    FROM joined_left lj
    FULL OUTER JOIN web_returns wr2
        ON lj.wr_returned_date_sk = wr2.wr_returned_date_sk
        AND lj.wr_return_amt = wr2.wr_return_amt
    LEFT JOIN customer_demographics cd2
        ON wr2.wr_returning_cdemo_sk = cd2.cd_demo_sk
    LEFT JOIN household_demographics hd2
        ON wr2.wr_returning_hdemo_sk = hd2.hd_demo_sk
),
key_set AS (
    SELECT cd_demo_sk FROM customer_demographics
    EXCEPT
    SELECT wr_refunded_cdemo_sk FROM web_returns
),
final AS (
    SELECT
        fj.wr_returned_date_sk,
        fj.wr_return_amt,
        fj.cd_demo_sk,
        fj.hd_demo_sk,
        fj.returning_cd_demo_sk,
        fj.returning_hd_demo_sk,
        ROW_NUMBER() OVER (ORDER BY fj.wr_return_amt DESC) AS rn_global,
        RANK() OVER (PARTITION BY fj.cd_demo_sk ORDER BY fj.wr_return_amt DESC) AS rank_by_customer,
        (SELECT SUM(wr3.wr_return_amt)
         FROM web_returns wr3
         WHERE wr3.wr_returning_cdemo_sk = fj.cd_demo_sk) AS total_return_by_customer,
        CASE 
            WHEN fj.hd_demo_sk IS NULL THEN 'No Household'
            ELSE 'Has Household'
        END AS household_status
    FROM full_joined fj
    WHERE fj.wr_return_amt IS NOT NULL
),
final_flagged AS (
    SELECT
        f.*,
        CASE WHEN ks.cd_demo_sk IS NOT NULL THEN 1 ELSE 0 END AS is_customer_without_returns
    FROM final f
    LEFT JOIN key_set ks
        ON f.cd_demo_sk = ks.cd_demo_sk
)
SELECT
    wr_returned_date_sk,
    wr_return_amt,
    cd_demo_sk,
    hd_demo_sk,
    returning_cd_demo_sk,
    returning_hd_demo_sk,
    rn_global,
    rank_by_customer,
    total_return_by_customer,
    household_status,
    is_customer_without_returns
FROM final_flagged
WHERE rn_global <= 100
ORDER BY rn_global
LIMIT 100
