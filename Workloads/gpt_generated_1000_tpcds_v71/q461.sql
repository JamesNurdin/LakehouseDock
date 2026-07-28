WITH per_category_demo AS (
    SELECT
        i.i_category_id AS category_id,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_net_loss) AS avg_net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    LEFT JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_category_id IN (5, 8, 6)
      AND i.i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2005-12-31'
      AND cd.cd_purchase_estimate > 1000
      AND cd.cd_dep_college_count <= 3
      AND c_ref.c_birth_month = 7
    GROUP BY i.i_category_id, cd.cd_gender, cd.cd_marital_status
)
SELECT
    pc.category_id,
    pc.gender,
    pc.marital_status,
    pc.total_return_amount,
    pc.return_cnt,
    pc.avg_net_loss,
    RANK() OVER (PARTITION BY pc.category_id ORDER BY pc.total_return_amount DESC) AS return_rank,
    (SELECT MAX(total_return_amount) FROM per_category_demo) AS max_total_return_amount
FROM per_category_demo pc
WHERE pc.total_return_amount > (
        SELECT AVG(total_return_amount) FROM per_category_demo
      )
  AND EXISTS (
        SELECT 1 FROM (
            SELECT DISTINCT cd2.cd_gender
            FROM customer_demographics cd2
            WHERE cd2.cd_dep_employed_count > 2
        ) g
        WHERE g.cd_gender = pc.gender
      )
ORDER BY pc.category_id, return_rank
LIMIT 100
