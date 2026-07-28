WITH returns_agg AS (
    SELECT
        ca.ca_state,
        cd.cd_gender,
        c.c_birth_month,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        MIN(cr.cr_return_ship_cost) AS min_ship_cost
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month = 7
      AND ca.ca_street_type = 'Ave'
      AND cd.cd_gender = 'F'
      AND cr.cr_return_tax > 5.00
      AND wp.wp_char_count > 1000
    GROUP BY ca.ca_state, cd.cd_gender, c.c_birth_month
    HAVING SUM(cr.cr_return_amount) > 1000
       AND COUNT(DISTINCT cr.cr_order_number) > 5
)
SELECT
    ca_state,
    cd_gender,
    c_birth_month,
    distinct_orders,
    total_return_amount,
    avg_return_tax,
    min_ship_cost
FROM returns_agg
ORDER BY total_return_amount DESC
