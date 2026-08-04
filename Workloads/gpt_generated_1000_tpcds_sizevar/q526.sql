/*
Goal: Compare the total net loss from catalog returns for customers born in Jordan (as refunded customers) versus those born in Switzerland (as returning customers). The query categorizes loss levels, applies a sample to the Switzerland side, uses a scalar subquery for average net loss filtering, includes a CASE expression, ensures distinct rows, combines the two perspectives with a UNION, orders by loss, and limits the output.
*/
WITH refunded AS (
    SELECT
        c.c_birth_country AS birth_country,
        hd.hd_buy_potential AS buy_potential,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        CASE
            WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH'
            WHEN SUM(cr.cr_net_loss) > 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_category
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_country = 'JORDAN'
    GROUP BY c.c_birth_country, hd.hd_buy_potential
),
returning AS (
    SELECT
        c.c_birth_country AS birth_country,
        hd.hd_buy_potential AS buy_potential,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        CASE
            WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH'
            WHEN SUM(cr.cr_net_loss) > 5000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_category
    FROM catalog_returns cr
    JOIN (SELECT * FROM customer TABLESAMPLE BERNOULLI (10)) c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE c.c_birth_country = 'SWITZERLAND'
    GROUP BY c.c_birth_country, hd.hd_buy_potential
)
SELECT DISTINCT
    combined.birth_country,
    combined.buy_potential,
    combined.total_net_loss,
    combined.distinct_orders,
    combined.loss_category
FROM (
    SELECT birth_country, buy_potential, total_net_loss, distinct_orders, loss_category
    FROM refunded
    UNION ALL
    SELECT birth_country, buy_potential, total_net_loss, distinct_orders, loss_category
    FROM returning
) combined
WHERE combined.total_net_loss > (
    SELECT AVG(cr2.cr_net_loss)
    FROM catalog_returns cr2
    WHERE cr2.cr_store_credit > 0
)
ORDER BY combined.total_net_loss DESC
LIMIT 100
