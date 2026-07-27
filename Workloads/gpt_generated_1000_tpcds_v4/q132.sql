WITH agg_returns AS (
    SELECT
        cr.c_customer_id,
        cr.c_email_address,
        cd_ref.cd_gender,
        cd_ref.cd_marital_status,
        cr.c_birth_month,
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count,
        AVG(wr.wr_return_amt) AS avg_return_amount
    FROM web_returns wr
    JOIN customer cr
      ON wr.wr_refunded_customer_sk = cr.c_customer_sk
    JOIN customer_demographics cd_ref
      ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer cr_ret
      ON wr.wr_returning_customer_sk = cr_ret.c_customer_sk
    JOIN customer_demographics cd_cur
      ON cr.c_current_cdemo_sk = cd_cur.cd_demo_sk
    WHERE cd_ref.cd_purchase_estimate > 3000
      AND cd_ref.cd_dep_employed_count >= 2
      AND cr.c_birth_month IN (5, 8, 9)
      AND wr.wr_return_amt > 100
      AND wr.wr_fee BETWEEN 10 AND 30
      AND cr.c_email_address LIKE '%@%'
    GROUP BY
        cr.c_customer_id,
        cr.c_email_address,
        cd_ref.cd_gender,
        cd_ref.cd_marital_status,
        cr.c_birth_month,
        wr.wr_item_sk
    HAVING COUNT(*) >= 2
)
SELECT
    a.c_customer_id,
    a.c_email_address,
    a.cd_gender,
    a.cd_marital_status,
    a.c_birth_month,
    a.wr_item_sk,
    a.total_return_amount,
    a.return_count,
    a.avg_return_amount,
    (SELECT AVG(wr2.wr_return_amt)
     FROM web_returns wr2
     WHERE wr2.wr_item_sk = a.wr_item_sk) AS avg_item_return_amount,
    RANK() OVER (PARTITION BY a.c_birth_month ORDER BY a.total_return_amount DESC) AS rank_by_birth_month,
    CASE
        WHEN a.total_return_amount > 500 THEN 'High'
        ELSE 'Normal'
    END AS amount_category
FROM agg_returns a
ORDER BY rank_by_birth_month, total_return_amount DESC
LIMIT 100
