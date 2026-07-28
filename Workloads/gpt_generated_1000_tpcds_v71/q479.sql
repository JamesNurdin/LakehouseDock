WITH sales_detail AS (
    SELECT
        i.i_category,
        ca.ca_city,
        i.i_product_name,
        REGEXP_EXTRACT(i.i_product_name, '^([^ ]+)', 1) AS first_word,
        CONCAT(i.i_category, ':', ca.ca_city) AS category_city,
        cs.cs_net_paid,
        cs.cs_net_profit,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        t.t_hour
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE REGEXP_LIKE(i.i_product_name, '(?i).*(chair|table).*')
      AND ca.ca_city LIKE 'San%'
      AND t.t_hour BETWEEN 8 AND 17
)
SELECT
    i_category,
    ca_city,
    first_word,
    profit_flag,
    SUM(cs_net_paid) AS total_net_paid,
    COUNT(*) AS sales_cnt
FROM sales_detail
GROUP BY
    i_category,
    ca_city,
    first_word,
    profit_flag
ORDER BY total_net_paid DESC
LIMIT 100
