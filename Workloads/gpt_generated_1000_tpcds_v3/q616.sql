WITH sub_a AS (
    SELECT
        c.c_customer_id,
        wp.wp_type,
        cs.cs_ship_mode_sk,
        COUNT(DISTINCT cs.cs_order_number) AS orders_count,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(cs.cs_wholesale_cost) AS avg_wholesale_cost,
        MIN(cs.cs_net_paid_inc_ship_tax) AS min_net_paid_inc_ship_tax,
        MAX(wr.wr_refunded_cash) AS max_refunded_cash
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wp.wp_web_page_sk = wr.wr_web_page_sk
           AND wp.wp_customer_sk = c.c_customer_sk
    WHERE cs.cs_wholesale_cost > 30.00
      AND cs.cs_wholesale_cost < 80.00
      AND cs.cs_ship_mode_sk IN (2, 3, 9)
      AND c.c_birth_day = 13
      AND wr.wr_refunded_cash > 200.00
      AND wp.wp_type = 'product'
    GROUP BY c.c_customer_id, wp.wp_type, cs.cs_ship_mode_sk
),
sub_b AS (
    SELECT
        c.c_customer_id,
        wp.wp_type,
        cs.cs_ship_mode_sk,
        COUNT(DISTINCT cs.cs_order_number) AS orders_count,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(cs.cs_wholesale_cost) AS avg_wholesale_cost,
        MIN(cs.cs_net_paid_inc_ship_tax) AS min_net_paid_inc_ship_tax,
        MAX(wr.wr_refunded_cash) AS max_refunded_cash
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_ship_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wp.wp_web_page_sk = wr.wr_web_page_sk
           AND wp.wp_customer_sk = c.c_customer_sk
    WHERE cs.cs_wholesale_cost BETWEEN 5.00 AND 20.00
      AND cs.cs_ship_mode_sk = 15
      AND c.c_birth_day = 9
      AND wr.wr_refunded_cash < 100.00
      AND wp.wp_type = 'advertisement'
    GROUP BY c.c_customer_id, wp.wp_type, cs.cs_ship_mode_sk
)
SELECT
    c_customer_id,
    wp_type,
    cs_ship_mode_sk,
    orders_count,
    total_net_paid,
    total_return_amt,
    avg_wholesale_cost,
    min_net_paid_inc_ship_tax,
    max_refunded_cash
FROM (
    SELECT * FROM sub_a
    UNION ALL
    SELECT * FROM sub_b
) combined
ORDER BY total_net_paid DESC
LIMIT 100
