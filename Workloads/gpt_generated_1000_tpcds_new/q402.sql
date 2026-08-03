WITH joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        cp.cp_department,
        cp.cp_catalog_page_number,
        w1.w_state AS ship_state,
        w2.w_state AS bill_state,
        cust_bill.c_customer_id AS bill_customer_id,
        cust_ship.c_customer_id AS ship_customer_id,
        wp_bill.wp_url AS bill_wp_url,
        wp_ship.wp_url AS ship_wp_url
    FROM catalog_sales cs
    JOIN customer cust_bill
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer cust_ship
        ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_page cp_alt
        ON cs.cs_catalog_page_sk = cp_alt.cp_catalog_page_sk
    JOIN warehouse w1
        ON cs.cs_warehouse_sk = w1.w_warehouse_sk
    JOIN warehouse w2
        ON cs.cs_warehouse_sk = w2.w_warehouse_sk
    JOIN (SELECT * FROM item TABLESAMPLE BERNOULLI (10)) i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN web_page wp_bill
        ON wp_bill.wp_customer_sk = cust_bill.c_customer_sk
    JOIN web_page wp_ship
        ON wp_ship.wp_customer_sk = cust_ship.c_customer_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'
),

order_set_a AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 5
),

order_set_b AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_net_profit > 0
),

common_orders AS (
    SELECT cs_order_number
    FROM order_set_a
    INTERSECT
    SELECT cs_order_number
    FROM order_set_b
),

ranked AS (
    SELECT
        j.*, 
        ROW_NUMBER() OVER (PARTITION BY ship_state ORDER BY cs_net_paid DESC) AS rn
    FROM joined j
    WHERE j.cs_order_number IN (SELECT cs_order_number FROM common_orders)
),

filtered AS (
    SELECT *
    FROM ranked
    WHERE rn <= 5
),

unioned AS (
    SELECT cs_order_number, cs_net_paid, ship_state, rn
    FROM filtered
    UNION
    SELECT cs_order_number, cs_net_paid, ship_state, rn
    FROM filtered
    WHERE cs_quantity < 10
)

SELECT
    cs_order_number,
    cs_net_paid,
    ship_state,
    rn
FROM unioned
ORDER BY ship_state, cs_net_paid DESC
OFFSET 10
LIMIT 100
