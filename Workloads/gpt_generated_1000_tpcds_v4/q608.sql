WITH refunded_demo AS (
    SELECT cd_demo_sk, cd_credit_rating, cd_dep_college_count
    FROM customer_demographics
    WHERE cd_credit_rating = 'Good'
),
returning_demo AS (
    SELECT cd_demo_sk, cd_gender
    FROM customer_demographics
    WHERE cd_gender = 'F'
),
item_filtered AS (
    SELECT i_item_sk, i_brand, i_size, i_current_price
    FROM item
    WHERE i_brand = 'importobrand #6'
      AND i_size = 'large'
),
item_avg_return AS (
    SELECT wr_item_sk, AVG(wr_return_amt) AS avg_return_amt_item
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT
    i.i_brand,
    i.i_size,
    rd.cd_credit_rating,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_fee) AS avg_fee,
    MIN(wr.wr_return_quantity) AS min_qty,
    MAX(wr.wr_return_quantity) AS max_qty,
    CASE
        WHEN SUM(wr.wr_return_amt) > 5000 THEN 'High'
        WHEN SUM(wr.wr_return_amt) > 2000 THEN 'Medium'
        ELSE 'Low'
    END AS return_level,
    AVG(ar.avg_return_amt_item) AS avg_item_return_amt
FROM web_returns wr
JOIN item_filtered i
    ON wr.wr_item_sk = i.i_item_sk
JOIN refunded_demo rd
    ON wr.wr_refunded_cdemo_sk = rd.cd_demo_sk
JOIN returning_demo rtd
    ON wr.wr_returning_cdemo_sk = rtd.cd_demo_sk
JOIN item_avg_return ar
    ON wr.wr_item_sk = ar.wr_item_sk
WHERE wr.wr_fee > 10
  AND wr.wr_return_amt > 20
  AND wr.wr_return_quantity >= 1
  AND i.i_current_price BETWEEN 10 AND 1000
  AND rd.cd_dep_college_count >= 1
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = wr.wr_item_sk
          AND wr2.wr_fee > wr.wr_fee
    )
GROUP BY
    i.i_brand,
    i.i_size,
    rd.cd_credit_rating
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amt DESC
LIMIT 100
