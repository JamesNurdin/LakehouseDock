WITH joined AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        ca_bill.ca_city AS bill_city,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_city AS ship_city,
        ca_ship.ca_state AS ship_state,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month_seq,
        d_sold.d_date AS sold_date,
        d_ship.d_year AS ship_year,
        d_ship.d_month_seq AS ship_month_seq,
        d_ship.d_date AS ship_date,
        s.s_store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        wp.wp_url,
        wp.wp_type,
        d_web_creation.d_year AS web_creation_year,
        d_web_creation.d_month_seq AS web_creation_month_seq,
        d_web_access.d_year AS web_access_year,
        d_web_access.d_month_seq AS web_access_month_seq
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    JOIN date_dim d_web_creation
        ON wp.wp_creation_date_sk = d_web_creation.d_date_sk
    JOIN date_dim d_web_access
        ON wp.wp_access_date_sk = d_web_access.d_date_sk
    WHERE cs.cs_net_paid > 0
      AND d_sold.d_year BETWEEN 2015 AND 2020
      AND s.s_state = 'CA'
      AND wp.wp_type = 'product'
),
agg AS (
    SELECT
        cs_item_sk,
        sold_year,
        sold_month_seq,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        AVG(cs_sales_price) AS avg_sales_price,
        MIN(cs_net_profit) AS min_net_profit,
        MAX(cs_net_profit) AS max_net_profit
    FROM joined
    GROUP BY cs_item_sk, sold_year, sold_month_seq
)
SELECT
    j.cs_order_number,
    j.cs_item_sk,
    j.cs_quantity,
    j.cs_sales_price,
    j.cs_net_paid,
    j.cs_net_profit,
    j.bill_city,
    j.bill_state,
    j.ship_city,
    j.ship_state,
    j.sold_year,
    j.sold_month_seq,
    j.ship_year,
    j.ship_month_seq,
    j.s_store_name,
    j.store_city,
    j.store_state,
    j.wp_url,
    j.wp_type,
    j.web_creation_year,
    j.web_creation_month_seq,
    j.web_access_year,
    j.web_access_month_seq,
    a.total_net_paid,
    a.total_quantity,
    a.distinct_orders,
    a.avg_sales_price,
    a.min_net_profit,
    a.max_net_profit,
    ROW_NUMBER() OVER (PARTITION BY j.cs_item_sk ORDER BY j.cs_net_paid DESC) AS item_net_paid_rank,
    RANK() OVER (PARTITION BY j.sold_year ORDER BY a.total_net_paid DESC) AS yearly_sales_rank
FROM joined j
JOIN agg a
    ON j.cs_item_sk = a.cs_item_sk
   AND j.sold_year = a.sold_year
   AND j.sold_month_seq = a.sold_month_seq
WHERE j.cs_net_paid > 0
ORDER BY j.cs_net_paid DESC
LIMIT 100
