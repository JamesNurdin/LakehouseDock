WITH overall_avg AS (
    SELECT avg(cr_net_loss) AS overall_avg_net_loss
    FROM catalog_returns
)

SELECT
    w.w_warehouse_id,
    w.w_city,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
    REGEXP_EXTRACT(c.c_email_address, '@([^.]*)\\..*', 1) AS email_domain,
    COUNT(*) AS returns_count,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_net_loss) AS avg_net_loss
FROM catalog_returns cr
JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE
    REGEXP_LIKE(c.c_email_address, '^.+@example\\.com$')
    AND w.w_city LIKE 'F%'
    AND cd.cd_gender = 'M'
    AND EXISTS (
        SELECT 1
        FROM customer_demographics cd_cur
        WHERE cd_cur.cd_demo_sk = c.c_current_cdemo_sk
          AND cd_cur.cd_credit_rating = 'Excellent'
    )
GROUP BY
    w.w_warehouse_id,
    w.w_city,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address
HAVING
    COUNT(*) > 5
    AND AVG(cr.cr_net_loss) > (SELECT overall_avg_net_loss FROM overall_avg)
ORDER BY avg_net_loss DESC
LIMIT 100
