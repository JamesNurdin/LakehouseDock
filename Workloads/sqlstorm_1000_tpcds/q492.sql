WITH unified_sales AS (
    SELECT 'web' AS channel,
           ws_sold_date_sk AS sold_date_sk,
           ws_item_sk AS item_sk,
           ws_bill_customer_sk AS customer_sk,
           ws_net_paid AS net_paid,
           ws_order_number AS order_number
    FROM web_sales
    UNION ALL
    SELECT 'store' AS channel,
           ss_sold_date_sk,
           ss_item_sk,
           ss_customer_sk,
           ss_net_paid,
           ss_ticket_number
    FROM store_sales
    UNION ALL
    SELECT 'catalog' AS channel,
           cs_sold_date_sk,
           cs_item_sk,
           cs_bill_customer_sk,
           cs_net_paid,
           cs_order_number
    FROM catalog_sales
),
base AS (
    SELECT
        us.channel,
        d.d_year,
        us.order_number,
        us.net_paid,
        LOWER(c.c_email_address) AS email,
        LENGTH(LOWER(c.c_email_address)) AS email_length,
        regexp_extract(LOWER(c.c_email_address), '@(.+)$', 1) AS email_domain,
        LENGTH(regexp_extract(LOWER(c.c_email_address), '@(.+)$', 1)) AS email_domain_length,
        CONCAT_WS(' ', c.c_first_name, c.c_last_name) AS customer_name,
        regexp_replace(i.i_product_name, '[^A-Za-z0-9 ]', '') AS clean_product_name,
        LENGTH(regexp_replace(i.i_product_name, '[^A-Za-z0-9 ]', '')) AS clean_product_name_length,
        SUBSTRING(i.i_item_desc FROM 1 FOR 30) AS item_desc_snippet,
        TRIM(BOTH ' ' FROM CONCAT_WS(', ', ca.ca_city, ca.ca_state, ca.ca_country)) AS address_normalized,
        CARDINALITY(SPLIT(i.i_product_name, ' ')) AS product_name_word_count,
        ARRAY_JOIN(SPLIT(i.i_product_name, ' '), '|') AS product_name_piped,
        REPLACE(CAST(d.d_date AS VARCHAR), '-', '') AS yyyymmdd
    FROM unified_sales us
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    JOIN customer c ON us.customer_sk = c.c_customer_sk
    JOIN item i ON us.item_sk = i.i_item_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT
    channel,
    d_year,
    order_number,
    customer_name,
    email,
    email_length,
    email_domain,
    email_domain_length,
    clean_product_name,
    clean_product_name_length,
    item_desc_snippet,
    address_normalized,
    product_name_word_count,
    product_name_piped,
    yyyymmdd,
    net_paid,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY net_paid DESC) AS rn,
    ARRAY_JOIN(array_agg(DISTINCT email_domain) OVER (PARTITION BY channel, d_year), ',') AS domains_per_channel_year
FROM base
ORDER BY channel, d_year DESC, rn
