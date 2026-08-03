WITH sampled_item AS (
        SELECT *
        FROM item
        TABLESAMPLE BERNOULLI (10)
    ),
    joined AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk,
            ss.ss_quantity,
            ss.ss_sales_price,
            i.i_product_name,
            i.i_category,
            i.i_category_id,
            td.t_hour,
            td.t_meal_time,
            ca.ca_zip,
            ca.ca_state,
            CASE
                WHEN ss.ss_sales_price > 100 THEN 'high'
                ELSE 'normal'
            END AS price_band,
            substring(i.i_product_name, 1, 10) AS product_prefix,
            ca.ca_state || '-' || ca.ca_zip AS state_zip
        FROM store_sales ss
        FULL OUTER JOIN time_dim td
            ON ss.ss_sold_time_sk = td.t_time_sk
        LEFT JOIN sampled_item i
            ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE
            regexp_like(i.i_product_name, '[0-9]{2,}')
            AND ca.ca_zip LIKE '9%'
    )
SELECT
    price_band,
    i_category,
    product_prefix,
    state_zip,
    COUNT(DISTINCT ss_ticket_number) AS num_tickets,
    SUM(ss_sales_price) AS total_sales,
    AVG(ss_quantity) AS avg_quantity,
    MAX(t_hour) AS max_hour
FROM joined
WHERE ss_ticket_number NOT IN (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_ext_discount_amt > 0
    )
GROUP BY
    price_band,
    i_category,
    product_prefix,
    state_zip
ORDER BY total_sales DESC
LIMIT 100
