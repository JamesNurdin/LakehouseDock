WITH customer_returns_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_state,
        hd.hd_income_band_sk,
        COUNT(cr.cr_order_number)                AS num_returns,
        SUM(cr.cr_return_amount)                 AS total_return_amount,
        SUM(cr.cr_fee)                           AS total_fee,
        AVG(cr.cr_return_amount)                 AS avg_return_amount
    FROM catalog_returns cr
    INNER JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    INNER JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        cr.cr_fee > 10.00
        AND cr.cr_return_quantity > 1
        AND cr.cr_return_amount > 0
        AND cr.cr_returned_date_sk BETWEEN 2450646 AND 2452167
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_state,
        hd.hd_income_band_sk
)
SELECT
    cra.ca_state,
    cra.hd_income_band_sk,
    COUNT(*)                                      AS num_customers,
    SUM(cra.num_returns)                          AS total_returns,
    AVG(cra.total_return_amount)                  AS avg_return_amount_per_customer,
    AVG(cra.avg_return_amount)                    AS avg_avg_return_amount,
    (SELECT MIN(cr_sub.cr_fee) FROM catalog_returns cr_sub) AS overall_min_fee
FROM customer_returns_agg cra
WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = cra.c_customer_sk
          AND wp.wp_rec_start_date >= DATE '2001-01-01'
          AND wp.wp_max_ad_count >= 2
    )
    AND cra.ca_state IN ('TX', 'CA', 'NY')
    AND cra.total_fee > 50.00
    AND cra.num_returns >= 2
GROUP BY
    cra.ca_state,
    cra.hd_income_band_sk
HAVING AVG(cra.total_return_amount) > 100.00
ORDER BY avg_return_amount_per_customer DESC
