WITH
    store_agg AS (
        SELECT
            ss_cdemo_sk AS cd_demo_sk,
            ss_hdemo_sk AS hd_demo_sk,
            SUM(ss_net_paid) AS total_sales,
            SUM(ss_ext_discount_amt) AS total_discount,
            COUNT(*) AS sales_cnt
        FROM store_sales
        GROUP BY ss_cdemo_sk, ss_hdemo_sk
    ),
    web_ret_agg AS (
        SELECT
            wr_refunded_cdemo_sk AS cd_demo_sk,
            wr_refunded_hdemo_sk AS hd_demo_sk,
            SUM(wr_return_amt) AS total_returns,
            SUM(wr_net_loss) AS total_loss,
            COUNT(*) AS returns_cnt
        FROM web_returns
        GROUP BY wr_refunded_cdemo_sk, wr_refunded_hdemo_sk
    ),
    joined_agg AS (
        SELECT
            COALESCE(s.cd_demo_sk, w.cd_demo_sk) AS cd_demo_sk,
            COALESCE(s.hd_demo_sk, w.hd_demo_sk) AS hd_demo_sk,
            s.total_sales,
            s.total_discount,
            s.sales_cnt,
            w.total_returns,
            w.total_loss,
            w.returns_cnt
        FROM store_agg s
        FULL OUTER JOIN web_ret_agg w
            ON s.cd_demo_sk = w.cd_demo_sk
            AND s.hd_demo_sk = w.hd_demo_sk
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY COALESCE(j.total_sales, 0) DESC) AS rn,
    cd.cd_gender,
    cd.cd_credit_rating,
    hd.hd_buy_potential,
    regexp_extract(hd.hd_buy_potential, '([0-9]+)-([0-9]+)', 1) AS lower_range,
    regexp_extract(hd.hd_buy_potential, '([0-9]+)-([0-9]+)', 2) AS upper_range,
    CASE
        WHEN hd.hd_buy_potential LIKE '>%' THEN 'Very High'
        WHEN hd.hd_buy_potential LIKE '0-%' THEN 'Low'
        ELSE 'Medium'
    END AS potential_category,
    cd.cd_gender || '-' || cd.cd_credit_rating AS customer_segment,
    j.total_sales,
    j.total_discount,
    j.sales_cnt,
    j.total_returns,
    j.total_loss,
    j.returns_cnt,
    (SELECT COUNT(DISTINCT cd2.cd_gender || '-' || cd2.cd_credit_rating)
     FROM customer_demographics cd2
     WHERE regexp_like(cd2.cd_credit_rating, 'Risk')) AS distinct_risk_segments,
    (SELECT AVG(j2.total_sales)
     FROM joined_agg j2
     JOIN customer_demographics cd2 ON j2.cd_demo_sk = cd2.cd_demo_sk
     WHERE cd2.cd_credit_rating = cd.cd_credit_rating) AS avg_sales_same_rating,
    CASE WHEN EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_refunded_cdemo_sk = j.cd_demo_sk
          AND wr.wr_refunded_hdemo_sk = j.hd_demo_sk
          AND wr.wr_return_amt > 5000
    ) THEN 'Yes' ELSE 'No' END AS has_big_return
FROM joined_agg j
LEFT JOIN customer_demographics cd
    ON j.cd_demo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
    ON j.hd_demo_sk = hd.hd_demo_sk
WHERE
    regexp_like(cd.cd_credit_rating, 'Risk')
    AND (hd.hd_buy_potential LIKE '>%' OR hd.hd_buy_potential LIKE '0-%')
    AND j.total_sales > COALESCE((SELECT AVG(total_sales) FROM joined_agg), 0)
ORDER BY rn
LIMIT 100
