WITH
    left_joined AS (
        SELECT
            cr.cr_order_number AS cr_order_number,
            cr.cr_returned_date_sk AS cr_returned_date_sk,
            cr.cr_return_amount AS cr_return_amount,
            cr.cr_net_loss AS cr_net_loss,
            cr.cr_return_quantity AS cr_return_quantity,
            cr.cr_return_tax AS cr_return_tax,
            cr.cr_return_ship_cost AS cr_return_ship_cost,
            cu.c_customer_id AS c_customer_id,
            cu.c_first_sales_date_sk AS c_first_sales_date_sk,
            cu.c_birth_year AS c_birth_year,
            cu.c_preferred_cust_flag AS c_preferred_cust_flag,
            NULL AS fee_flag
        FROM catalog_returns cr
        LEFT JOIN customer cu
            ON cr.cr_returning_customer_sk = cu.c_customer_sk
        WHERE cr.cr_return_quantity > 1
          AND cr.cr_return_tax > 20.00
          AND cr.cr_return_ship_cost < 3000.00
          AND cu.c_birth_year BETWEEN 1960 AND 1980
          AND cu.c_preferred_cust_flag = 'Y'
    ),
    inner_joined AS (
        SELECT
            cr.cr_order_number AS cr_order_number,
            cr.cr_returned_date_sk AS cr_returned_date_sk,
            cr.cr_return_amount AS cr_return_amount,
            cr.cr_net_loss AS cr_net_loss,
            cr.cr_return_quantity AS cr_return_quantity,
            cr.cr_return_tax AS cr_return_tax,
            cr.cr_return_ship_cost AS cr_return_ship_cost,
            cu.c_customer_id AS c_customer_id,
            cu.c_first_sales_date_sk AS c_first_sales_date_sk,
            cu.c_birth_year AS c_birth_year,
            cu.c_preferred_cust_flag AS c_preferred_cust_flag,
            CASE WHEN cr.cr_fee > 0 THEN 'FEE_ASSIGNED' ELSE 'NO_FEE' END AS fee_flag
        FROM catalog_returns cr
        INNER JOIN customer cu
            ON cr.cr_refunded_customer_sk = cu.c_customer_sk
        WHERE cr.cr_refunded_cash > 0
          AND cr.cr_reversed_charge > 0
          AND cr.cr_fee > 5.00
          AND cu.c_birth_year BETWEEN 1970 AND 1990
          AND cu.c_preferred_cust_flag = 'N'
    ),
    combined AS (
        SELECT
            cr_order_number,
            cr_returned_date_sk,
            cr_return_amount,
            cr_net_loss,
            cr_return_quantity,
            cr_return_tax,
            cr_return_ship_cost,
            c_customer_id,
            c_first_sales_date_sk,
            c_birth_year,
            c_preferred_cust_flag,
            fee_flag
        FROM left_joined
        UNION ALL
        SELECT
            cr_order_number,
            cr_returned_date_sk,
            cr_return_amount,
            cr_net_loss,
            cr_return_quantity,
            cr_return_tax,
            cr_return_ship_cost,
            c_customer_id,
            c_first_sales_date_sk,
            c_birth_year,
            c_preferred_cust_flag,
            fee_flag
        FROM inner_joined
    ),
    intersect_keys AS (
        SELECT cr_order_number
        FROM catalog_returns
        WHERE cr_return_quantity > 5
        INTERSECT
        SELECT cr_order_number
        FROM catalog_returns
        WHERE cr_return_tax > 100.00
    )
SELECT
    c.cr_order_number,
    c.cr_returned_date_sk,
    c.cr_return_amount,
    c.cr_net_loss,
    c.c_customer_id,
    c.c_first_sales_date_sk,
    c.fee_flag,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.cr_net_loss DESC) AS rn_by_customer,
    RANK() OVER (ORDER BY c.cr_net_loss DESC) AS net_loss_rank,
    SUM(c.cr_net_loss) OVER (
        PARTITION BY c.c_customer_id
        ORDER BY c.cr_returned_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_net_loss
FROM combined c
JOIN intersect_keys ik
    ON c.cr_order_number = ik.cr_order_number
WHERE c.cr_return_amount IS NOT NULL
ORDER BY c.cr_net_loss DESC
LIMIT 100
