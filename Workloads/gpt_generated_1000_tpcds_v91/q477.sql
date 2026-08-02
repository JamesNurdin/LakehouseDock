WITH ws_sample AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
),

agg AS (
    SELECT
        c_bill.c_customer_sk AS cust_sk,
        c_bill.c_customer_id AS customer_id,
        d_sold.d_year AS sales_year,
        d_sold.d_month_seq AS month_seq,
        p.p_promo_name AS promo_name,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        ca_bill.ca_city AS billing_city,
        ca_ship.ca_city AS shipping_city,
        cd_bill.cd_gender AS gender,
        cd_bill.cd_education_status AS education,
        inventory.inv_quantity_on_hand AS inventory_on_hand,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM ws_sample ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN time_dim t_time
        ON ws.ws_sold_time_sk = t_time.t_time_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
        AND p.p_discount_active = 'Y'
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN inventory
        ON inventory.inv_date_sk = d_sold.d_date_sk
        AND inventory.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d_sold.d_year = 2001
    GROUP BY
        c_bill.c_customer_sk,
        c_bill.c_customer_id,
        d_sold.d_year,
        d_sold.d_month_seq,
        p.p_promo_name,
        sm.sm_type,
        w.w_warehouse_name,
        ca_bill.ca_city,
        ca_ship.ca_city,
        cd_bill.cd_gender,
        cd_bill.cd_education_status,
        inventory.inv_quantity_on_hand
)

SELECT
    agg.cust_sk,
    agg.customer_id,
    agg.sales_year,
    agg.month_seq,
    agg.total_sales,
    agg.num_orders,
    agg.avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY agg.cust_sk ORDER BY agg.total_sales DESC) AS sales_rank,
    (SELECT COUNT(DISTINCT ws2.ws_promo_sk)
     FROM web_sales ws2
     WHERE ws2.ws_bill_customer_sk = agg.cust_sk
       AND ws2.ws_promo_sk IS NOT NULL) AS promo_count_for_customer,
    COALESCE(agg.promo_name, 'No Promotion') AS promo_name,
    agg.ship_mode_type,
    agg.w_warehouse_name,
    agg.billing_city,
    agg.shipping_city,
    agg.gender,
    agg.education,
    agg.inventory_on_hand
FROM agg
ORDER BY agg.total_sales DESC
LIMIT 100
