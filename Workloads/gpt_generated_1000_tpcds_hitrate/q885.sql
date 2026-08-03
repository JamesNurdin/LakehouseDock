WITH sales_agg AS (
    SELECT
        cs_bill_customer_sk,
        SUM(cs_net_paid_inc_ship) AS total_net_paid_inc_ship,
        SUM(cs_quantity) AS total_qty
    FROM catalog_sales
    WHERE cs_net_paid_inc_ship > (
        SELECT AVG(cs_net_paid_inc_ship) FROM catalog_sales
    )
    GROUP BY cs_bill_customer_sk
)
SELECT
    s.s_state,
    s.s_city,
    SUM(sa.total_net_paid_inc_ship) AS state_total_net_paid,
    SUM(sa.total_qty) AS state_total_qty,
    CASE
        WHEN SUM(sa.total_qty) > (
            SELECT AVG(qty_per_cust) FROM (
                SELECT SUM(cs_quantity) AS qty_per_cust
                FROM catalog_sales
                GROUP BY cs_bill_customer_sk
            ) t
        ) THEN 'High Volume' ELSE 'Low Volume'
    END AS volume_category
FROM sales_agg sa
JOIN customer c_bill
    ON sa.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN date_dim d_first_ship
    ON c_bill.c_first_shipto_date_sk = d_first_ship.d_date_sk
JOIN date_dim d_first_sales
    ON c_bill.c_first_sales_date_sk = d_first_sales.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_first_ship.d_date_sk
JOIN store s2
    ON s2.s_closed_date_sk = d_first_sales.d_date_sk
JOIN web_page wp1
    ON wp1.wp_customer_sk = c_bill.c_customer_sk
JOIN date_dim d_wp_create
    ON wp1.wp_creation_date_sk = d_wp_create.d_date_sk
JOIN web_page wp2
    ON wp2.wp_customer_sk = c_bill.c_customer_sk
JOIN date_dim d_wp_access
    ON wp2.wp_access_date_sk = d_wp_access.d_date_sk
JOIN date_dim d_ship
    ON EXISTS (
        SELECT 1
        FROM catalog_sales cs_raw
        WHERE cs_raw.cs_bill_customer_sk = sa.cs_bill_customer_sk
          AND cs_raw.cs_ship_date_sk = d_ship.d_date_sk
    )
WHERE EXISTS (
    SELECT 1
    FROM web_page wp_chk
    WHERE wp_chk.wp_customer_sk = c_bill.c_customer_sk
      AND wp_chk.wp_type = 'home'
)
GROUP BY s.s_state, s.s_city
HAVING SUM(sa.total_net_paid_inc_ship) > (
    SELECT MAX(total_net) FROM (
        SELECT SUM(cs_net_paid_inc_ship) AS total_net
        FROM catalog_sales
        GROUP BY cs_bill_customer_sk
    ) x
)
ORDER BY state_total_net_paid DESC
LIMIT 100
