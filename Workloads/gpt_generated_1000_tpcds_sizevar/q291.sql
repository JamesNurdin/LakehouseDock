WITH orders_without_return AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        WHERE cs.cs_bill_customer_sk = 3851857
        EXCEPT
        SELECT sr.sr_ticket_number
        FROM store_returns sr
        WHERE sr.sr_return_quantity > 0
    ),
    joined_data AS (
        SELECT
            ca.ca_state,
            d_s.d_year,
            cs.cs_order_number,
            cs.cs_ext_sales_price,
            cs.cs_net_profit,
            sr.sr_return_amt,
            wp.wp_char_count
        FROM catalog_sales cs
        JOIN date_dim d_s
            ON cs.cs_sold_date_sk = d_s.d_date_sk
        JOIN customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN store_returns sr
            ON sr.sr_addr_sk = ca.ca_address_sk
           AND sr.sr_returned_date_sk = d_s.d_date_sk
        JOIN web_page wp
            ON wp.wp_creation_date_sk = d_s.d_date_sk
        WHERE cs.cs_bill_customer_sk = 3851857
          AND cs.cs_ext_list_price > 5000
          AND cs.cs_ext_wholesale_cost < 2000
          AND d_s.d_year = 1998
          AND ca.ca_state = 'CA'
          AND d_s.d_quarter_name = '1901Q2'
          AND wp.wp_image_count >= 2
          AND wp.wp_char_count BETWEEN 500 AND 4000
          AND cs.cs_quantity >= 1
          AND cs.cs_ext_discount_amt < 1000
          AND cs.cs_order_number IN (SELECT cs_order_number FROM orders_without_return)
    )
SELECT
    agg.state,
    agg.year,
    agg.orders_cnt,
    agg.total_sales,
    agg.total_profit,
    agg.total_return_amount,
    agg.avg_page_chars,
    LAG(agg.total_profit) OVER (PARTITION BY agg.state ORDER BY agg.year) AS lag_total_profit
FROM (
    SELECT
        ca_state AS state,
        d_year AS year,
        COUNT(DISTINCT cs_order_number) AS orders_cnt,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(wp_char_count) AS avg_page_chars
    FROM joined_data
    GROUP BY ca_state, d_year
) agg
ORDER BY agg.state, agg.year DESC
LIMIT 100
