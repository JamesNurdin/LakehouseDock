WITH ss AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_credit_rating,
        cd.cd_marital_status,
        cd.cd_gender,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(cd.cd_credit_rating, 'Risk')
      AND cd.cd_gender LIKE 'M%'
      AND ss.ss_item_sk IN (
          SELECT DISTINCT wr.wr_item_sk
          FROM web_returns wr
          WHERE wr.wr_return_amt > 100
      )
    GROUP BY cd.cd_demo_sk, cd.cd_credit_rating, cd.cd_marital_status, cd.cd_gender
),
wr AS (
    SELECT
        cd.cd_demo_sk,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN customer_demographics cd
      ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE wr.wr_return_quantity > 10
      AND regexp_like(cast(wr.wr_returned_date_sk AS varchar), '^\\d+$')
    GROUP BY cd.cd_demo_sk
),
avg_est AS (
    SELECT AVG(cd_purchase_estimate) AS overall_avg_est
    FROM customer_demographics
)
SELECT DISTINCT
    CONCAT(cd.cd_credit_rating, ' - ', cd.cd_marital_status) AS segment_label,
    cd.cd_gender,
    regexp_extract(cd.cd_credit_rating, '(Low|High) Risk', 1) AS risk_level,
    ss.total_net_profit,
    wr.total_net_loss,
    ss.sales_cnt,
    wr.returns_cnt,
    cd.cd_purchase_estimate
FROM ss
JOIN wr
  ON ss.cd_demo_sk = wr.cd_demo_sk
JOIN customer_demographics cd
  ON ss.cd_demo_sk = cd.cd_demo_sk
WHERE cd.cd_purchase_estimate > (SELECT overall_avg_est FROM avg_est)
  AND cd.cd_marital_status LIKE 'W%'
  AND substring(cd.cd_credit_rating, 1, 4) = 'High'
ORDER BY ss.total_net_profit DESC, wr.total_net_loss ASC
LIMIT 100
