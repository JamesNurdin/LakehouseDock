WITH
    filtered_returns AS (
        SELECT
            cr_returned_date_sk,
            cr_return_amount,
            cr_return_quantity,
            cr_net_loss,
            cr_refunded_customer_sk,
            cr_refunded_cdemo_sk,
            cr_reason_sk
        FROM catalog_returns
        WHERE cr_return_amount > 50.0
          AND cr_return_quantity >= 1
          AND cr_return_tax IS NOT NULL
          AND cr_return_ship_cost < 20.0
          AND cr_fee BETWEEN 0 AND 10
          AND cr_returned_date_sk BETWEEN 2450000 AND 2452000
    ),
    agg_by_reason AS (
        SELECT
            r.r_reason_sk,
            r.r_reason_id,
            r.r_reason_desc,
            SUM(fr.cr_return_amount) AS total_return_amount,
            AVG(fr.cr_return_quantity) AS avg_return_quantity,
            COUNT(*) AS return_cnt,
            CASE
                WHEN SUM(fr.cr_net_loss) > 1000 THEN 'HIGH'
                WHEN SUM(fr.cr_net_loss) BETWEEN 500 AND 1000 THEN 'MEDIUM'
                ELSE 'LOW'
            END AS loss_category,
            AVG(cd.cd_dep_employed_count) AS avg_emp_deps,
            MAX(c.c_birth_year) AS max_birth_year
        FROM filtered_returns fr
        JOIN reason r ON fr.cr_reason_sk = r.r_reason_sk
        JOIN customer c ON fr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        WHERE c.c_birth_year BETWEEN 1950 AND 1980
          AND cd.cd_credit_rating IN ('Good', 'Low Risk')
          AND cd.cd_dep_employed_count >= 2
        GROUP BY r.r_reason_sk, r.r_reason_id, r.r_reason_desc
    ),
    common_reasons AS (
        SELECT cr_reason_sk
        FROM catalog_returns
        WHERE cr_return_amount > 100
          AND cr_return_quantity >= 2
        INTERSECT
        SELECT cr_reason_sk
        FROM catalog_returns
        WHERE cr_return_tax > 5
          AND cr_return_ship_cost < 15
    )
SELECT
    a.r_reason_id,
    a.r_reason_desc,
    a.total_return_amount,
    a.avg_return_quantity,
    a.return_cnt,
    a.loss_category,
    a.avg_emp_deps,
    a.max_birth_year
FROM agg_by_reason a
JOIN common_reasons cr ON a.r_reason_sk = cr.cr_reason_sk
WHERE a.total_return_amount > (SELECT AVG(total_return_amount) FROM agg_by_reason)
  AND a.return_cnt >= 10
  AND a.loss_category <> 'LOW'
ORDER BY a.total_return_amount DESC
LIMIT 100
