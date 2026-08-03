WITH cat_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_refunded_cdemo_sk IN (
        SELECT cd2.cd_demo_sk
        FROM customer_demographics cd2
        WHERE cd2.cd_credit_rating = 'Excellent'
    )
    GROUP BY CUBE (cd.cd_gender, cd.cd_marital_status)
),
web_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(wr.wr_return_amt) > 800 THEN 'HIGH' ELSE 'LOW' END AS amount_category
    FROM web_returns wr
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_web_page_sk = wr.wr_web_page_sk
          AND wp.wp_type = 'product'
    )
    GROUP BY CUBE (cd.cd_gender, cd.cd_marital_status)
),
unioned AS (
    SELECT * FROM cat_agg
    UNION ALL
    SELECT * FROM web_agg
),
hd_agg AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(*) AS hh_count
    FROM household_demographics hd
    GROUP BY hd.hd_income_band_sk, hd.hd_buy_potential
)
SELECT
    COALESCE(u.cd_gender, 'UNKNOWN') AS gender,
    COALESCE(u.cd_marital_status, 'UNKNOWN') AS marital_status,
    u.total_return_amount,
    u.return_cnt,
    u.amount_category,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    hd.hh_count,
    (SELECT AVG(total_return_amount) FROM unioned) AS overall_avg_return
FROM unioned u
FULL OUTER JOIN hd_agg hd
    ON true
ORDER BY u.total_return_amount DESC
LIMIT 100
