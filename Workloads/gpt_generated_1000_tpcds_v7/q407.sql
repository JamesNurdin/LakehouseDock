WITH filtered_sales AS (
    SELECT
        ss.ss_net_profit,
        i.i_item_desc,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        d.d_year,
        regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS extracted_code
    FROM
        store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND regexp_like(i.i_item_desc, '\\d{3}')
        AND ca.ca_city LIKE 'W%'
        AND ca.ca_zip LIKE '9%'
)
SELECT
    extracted_code,
    concat(ca_city, ', ', ca_state) AS location,
    sum(ss_net_profit) AS total_profit
FROM
    filtered_sales
GROUP BY
    extracted_code,
    concat(ca_city, ', ', ca_state)
ORDER BY
    total_profit DESC
