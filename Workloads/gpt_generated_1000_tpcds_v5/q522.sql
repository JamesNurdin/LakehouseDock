/*
Goal: Compare high‑value returns linked to refunded customers with moderate‑value returns linked to returning customers, categorizing net loss levels, showing each customer's average return amount, and filtering on household demographics.
*/
WITH refunded_returns AS (
    SELECT
        c.c_customer_id,
        cr.cr_return_amount,
        cr.cr_net_loss,
        CASE
            WHEN cr.cr_net_loss > 500 THEN 'High'
            WHEN cr.cr_net_loss > 100 THEN 'Medium'
            ELSE 'Low'
        END AS loss_category,
        'Refunded' AS return_role,
        (
            SELECT avg(cr_inner.cr_return_amount)
            FROM catalog_returns cr_inner
            WHERE cr_inner.cr_refunded_customer_sk = c.c_customer_sk
        ) AS avg_return_amount
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_amount > 1000
      AND hd.hd_income_band_sk >= 10
      AND EXISTS (
            SELECT 1
            FROM household_demographics hd2
            WHERE hd2.hd_demo_sk = c.c_current_hdemo_sk
              AND hd2.hd_dep_count <= 2
      )
),
returning_returns AS (
    SELECT
        c.c_customer_id,
        cr.cr_return_amount,
        cr.cr_net_loss,
        CASE
            WHEN cr.cr_net_loss > 500 THEN 'High'
            WHEN cr.cr_net_loss > 100 THEN 'Medium'
            ELSE 'Low'
        END AS loss_category,
        'Returning' AS return_role,
        (
            SELECT avg(cr_inner.cr_return_amount)
            FROM catalog_returns cr_inner
            WHERE cr_inner.cr_returning_customer_sk = c.c_customer_sk
        ) AS avg_return_amount
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_amount BETWEEN 500 AND 1000
      AND hd.hd_dep_count >= 5
)
SELECT
    c_customer_id,
    cr_return_amount,
    cr_net_loss,
    loss_category,
    return_role,
    avg_return_amount
FROM refunded_returns
UNION ALL
SELECT
    c_customer_id,
    cr_return_amount,
    cr_net_loss,
    loss_category,
    return_role,
    avg_return_amount
FROM returning_returns
ORDER BY loss_category, avg_return_amount DESC
LIMIT 100
