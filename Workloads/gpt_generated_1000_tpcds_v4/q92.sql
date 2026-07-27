WITH sales_joined AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        t.t_hour,
        t.t_meal_time,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_location_type
    FROM tpcds.store_sales ss
    JOIN tpcds.time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_country IN ('URUGUAY', 'UKRAINE')
      AND ss.ss_quantity > 30
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    sj.c_customer_id,
    sj.c_first_name,
    sj.c_last_name,
    sj.c_birth_country,
    sj.ca_city,
    sj.ca_state,
    sj.i_product_name,
    sj.i_current_price,
    sj.ss_quantity,
    sj.ss_net_paid,
    CASE
        WHEN sj.ss_net_profit > 100 THEN 'HIGH'
        WHEN sj.ss_net_profit > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (PARTITION BY sj.c_birth_country ORDER BY sj.ss_net_paid DESC) AS country_sales_rank,
    ROW_NUMBER() OVER (PARTITION BY sj.ca_state ORDER BY sj.ss_net_paid DESC) AS state_sales_rownum
FROM sales_joined sj
ORDER BY sj.ss_net_paid DESC
LIMIT 100
