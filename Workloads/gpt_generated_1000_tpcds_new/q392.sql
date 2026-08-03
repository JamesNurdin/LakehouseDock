WITH
    sales AS (
        SELECT
            ss.ss_ticket_number AS order_number,
            d.d_year,
            ss.ss_ext_sales_price AS amount,
            'Sale' AS src_type,
            ca.ca_state,
            hd.hd_buy_potential,
            p.p_promo_name
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        WHERE d.d_year BETWEEN 1999 AND 2001
          AND ca.ca_state IN ('CA', 'TX', 'NY')
          AND hd.hd_buy_potential <> 'Unknown'
          AND p.p_discount_active = 'Y'
    ),
    catalog_ret AS (
        SELECT
            cr.cr_order_number AS order_number,
            d.d_year,
            cr.cr_return_amount AS amount,
            'CatalogReturn' AS src_type,
            ca.ca_state,
            hd.hd_buy_potential,
            w.w_warehouse_name
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE d.d_year = 2000
          AND ca.ca_state = 'CA'
          AND hd.hd_vehicle_count > 1
          AND sm.sm_code = 'AIR'
          AND w.w_warehouse_sq_ft > 100000
    ),
    web_ret AS (
        SELECT
            wr.wr_order_number AS order_number,
            d.d_year,
            wr.wr_return_amt AS amount,
            'WebReturn' AS src_type,
            ca.ca_state,
            hd.hd_buy_potential,
            NULL AS warehouse_name
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2000
          AND ca.ca_state = 'CA'
          AND hd.hd_dep_count >= 3
          AND wr.wr_fee > 0
          AND wr.wr_return_ship_cost < 10
    ),
    common_orders AS (
        SELECT order_number FROM catalog_ret
        INTERSECT
        SELECT order_number FROM web_ret
    ),
    union_all_data AS (
        SELECT order_number, d_year, amount, src_type, ca_state, hd_buy_potential
        FROM sales
        UNION DISTINCT
        SELECT order_number, d_year, amount, src_type, ca_state, hd_buy_potential
        FROM catalog_ret
    ),
    ranked_data AS (
        SELECT
            u.order_number,
            u.d_year,
            u.amount,
            u.src_type,
            u.ca_state,
            u.hd_buy_potential,
            ROW_NUMBER() OVER (PARTITION BY u.d_year ORDER BY u.amount DESC) AS amount_rank,
            CASE
                WHEN u.amount > 1000 THEN 'High'
                WHEN u.amount > 100 THEN 'Medium'
                ELSE 'Low'
            END AS amount_category
        FROM union_all_data u
        WHERE u.order_number IN (SELECT order_number FROM common_orders)
    ),
    cross_dim AS (
        SELECT state, num
        FROM (SELECT DISTINCT ca_state AS state FROM customer_address WHERE ca_state IN ('CA','TX','NY') LIMIT 5) AS s
        CROSS JOIN (VALUES (1), (2), (3)) AS v(num)
    ),
    final AS (
        SELECT
            rd.order_number,
            rd.d_year,
            rd.amount,
            rd.src_type,
            rd.ca_state,
            rd.hd_buy_potential,
            rd.amount_rank,
            rd.amount_category,
            cd.state,
            cd.num,
            lt.total_return_amount
        FROM ranked_data rd
        JOIN cross_dim cd ON rd.ca_state = cd.state
        LEFT JOIN LATERAL (
            SELECT SUM(cr.cr_return_amount) AS total_return_amount
            FROM catalog_returns cr
            WHERE cr.cr_order_number = rd.order_number
        ) lt ON true
    )
SELECT *
FROM final
ORDER BY d_year DESC, amount_rank ASC, amount DESC
LIMIT 100
