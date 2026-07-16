WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        ca_ship.ca_city AS ship_city,
        d_ship.d_year,
        d_ship.d_month_seq AS ship_month_seq,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
       AND wp.wp_access_date_sk   = d_ship.d_date_sk
    WHERE cs.cs_quantity > 0
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        ca_ship.ca_city,
        d_ship.d_year,
        d_ship.d_month_seq
)
SELECT
    s_store_id,
    s_store_name,
    ship_city,
    d_year,
    ship_month_seq,
    distinct_pages,
    total_net_paid,
    total_net_profit,
    avg_discount,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS revenue_rank
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100
