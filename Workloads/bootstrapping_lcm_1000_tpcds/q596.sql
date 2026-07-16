WITH sales_detail AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_promo_sk,
        d_sold.d_date AS sold_date,
        d_sold.d_year AS sold_year,
        d_sold.d_quarter_name AS sold_quarter,
        d_ship.d_date AS ship_date,
        cust.c_customer_id AS bill_customer_id,
        cust.c_first_name,
        cust.c_last_name,
        cust.c_birth_year,
        d_first_sales.d_date AS first_sales_date,
        d_first_ship.d_date AS first_ship_date,
        p.p_promo_name,
        p.p_discount_active,
        d_promo_start.d_date AS promo_start_date,
        d_promo_end.d_date AS promo_end_date,
        st.s_store_id,
        st.s_store_name,
        st.s_closed_date_sk,
        d_store_close.d_date AS store_closed_date,
        ship_cust.c_customer_id AS ship_customer_id
    FROM catalog_sales cs
    INNER JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    INNER JOIN customer cust
        ON cs.cs_bill_customer_sk = cust.c_customer_sk
    LEFT JOIN customer ship_cust
        ON cs.cs_ship_customer_sk = ship_cust.c_customer_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN store st
        ON st.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_first_sales
        ON cust.c_first_sales_date_sk = d_first_sales.d_date_sk
    LEFT JOIN date_dim d_first_ship
        ON cust.c_first_shipto_date_sk = d_first_ship.d_date_sk
    LEFT JOIN date_dim d_store_close
        ON st.s_closed_date_sk = d_store_close.d_date_sk
    LEFT JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
)
SELECT
    sd.bill_customer_id,
    sd.c_first_name,
    sd.c_last_name,
    sd.sold_year,
    sd.sold_quarter,
    SUM(sd.cs_net_paid) AS total_net_paid,
    SUM(sd.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT sd.cs_order_number) AS distinct_orders,
    AVG(date_diff('day', sd.first_sales_date, sd.sold_date)) AS avg_days_since_first_sale,
    MAX(CASE WHEN sd.p_discount_active = 'Y' THEN sd.cs_net_paid ELSE 0 END) AS max_discounted_net_paid,
    COUNT(DISTINCT sd.s_store_id) AS stores_involved,
    MIN(sd.store_closed_date) AS earliest_store_close_date,
    MAX(sd.promo_start_date) AS latest_promo_start_date,
    MIN(sd.promo_end_date) AS earliest_promo_end_date,
    COUNT(DISTINCT sd.ship_customer_id) AS distinct_ship_customers
FROM sales_detail sd
GROUP BY
    sd.bill_customer_id,
    sd.c_first_name,
    sd.c_last_name,
    sd.sold_year,
    sd.sold_quarter
HAVING SUM(sd.cs_net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
