WITH sampled_cust AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating
    FROM customer_demographics
    TABLESAMPLE BERNOULLI (10)
),
intersected_demo AS (
    (SELECT cd_demo_sk FROM (
        SELECT wr_refunded_cdemo_sk AS cd_demo_sk
        FROM web_returns
        WHERE wr_return_amt > 100
        UNION
        SELECT wr_returning_cdemo_sk
        FROM web_returns
        WHERE wr_return_quantity > 1
    ))
    INTERSECT
    (SELECT cd_demo_sk FROM (
        SELECT wr_refunded_cdemo_sk AS cd_demo_sk
        FROM web_returns
        WHERE wr_return_tax > 10
        UNION
        SELECT wr_returning_cdemo_sk
        FROM web_returns
        WHERE wr_return_tax > 10
    ))
)
SELECT
    cd.cd_demo_sk,
    concat(cd.cd_gender, '-', cd.cd_marital_status) AS gender_marital,
    regexp_extract(cd.cd_credit_rating, '(\\w+)', 1) AS credit_prefix,
    CASE
        WHEN regexp_like(cd.cd_education_status, '^College') THEN 'College'
        ELSE 'Other'
    END AS education_group,
    COUNT(wr.wr_order_number) AS total_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    (SELECT SUM(wr2.wr_refunded_cash)
     FROM web_returns wr2
     WHERE wr2.wr_refunded_cdemo_sk = cd.cd_demo_sk) AS total_refunded_cash,
    (SELECT AVG(wr3.wr_return_tax)
     FROM web_returns wr3
     WHERE wr3.wr_returning_cdemo_sk = cd.cd_demo_sk) AS avg_return_tax
FROM sampled_cust cd
JOIN intersected_demo ids ON cd.cd_demo_sk = ids.cd_demo_sk
JOIN web_returns wr
    ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_credit_rating LIKE 'A%'
  AND EXISTS (
        SELECT 1
        FROM web_returns wr_exist
        WHERE wr_exist.wr_refunded_cdemo_sk = cd.cd_demo_sk
          AND wr_exist.wr_return_amt > 150
    )
GROUP BY
    cd.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    cd.cd_education_status
HAVING SUM(wr.wr_return_amt) > 500
ORDER BY total_return_amount DESC
LIMIT 100
