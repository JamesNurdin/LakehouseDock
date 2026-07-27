WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_order_number,
        cr.cr_returned_date_sk,
        cr.cr_reason_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_refunded_hdemo_sk,
        c.c_customer_sk,
        c.c_birth_year,
        ca.ca_state,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc
    FROM catalog_returns cr
    INNER JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    INNER JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    INNER JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        -- 1. Return amount greater than $100
        cr.cr_return_amount > 100
        -- 2. Customer birth year between 1970 and 1990
        AND c.c_birth_year BETWEEN 1970 AND 1990
        -- 3. State is California
        AND ca.ca_state = 'CA'
        -- 4. Income band upper bound above 50,000
        AND ib.ib_upper_bound > 50000
        -- 5. Reason description contains 'duplicate purchase' (using LIKE for realism)
        AND r.r_reason_desc LIKE '%duplicate purchase%'
        -- 6. Household has at least one vehicle
        AND hd.hd_vehicle_count >= 1
        -- 7. Semi‑join: customer must have a web page with more than 5 links and at least 2 images
        AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_customer_sk = c.c_customer_sk
              AND wp.wp_link_count > 5
              AND wp.wp_image_count >= 2
        )
)
SELECT
    ca_state,
    ib_lower_bound,
    r_reason_desc,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    MIN(cr_return_amount) AS min_return_amount,
    MAX(cr_return_amount) AS max_return_amount
FROM filtered_returns
GROUP BY
    ca_state,
    ib_lower_bound,
    r_reason_desc
ORDER BY
    total_return_amount DESC
LIMIT 100
