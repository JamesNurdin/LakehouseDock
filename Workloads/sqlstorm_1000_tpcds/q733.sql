WITH unified_sales AS (
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_quantity AS quantity,
        ws.ws_order_number AS order_num,
        ws.ws_sales_price AS sales_price,
        ws.ws_ext_discount_amt AS ext_discount,
        'Web' AS channel
    FROM web_sales ws
    UNION ALL
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_customer_sk AS cust_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_quantity AS quantity,
        ss.ss_ticket_number AS order_num,
        ss.ss_sales_price AS sales_price,
        ss.ss_ext_discount_amt AS ext_discount,
        'Store' AS channel
    FROM store_sales ss
),
sales_with_dims AS (
    SELECT
        us.*,
        d.d_year,
        d.d_month_seq
    FROM unified_sales us
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
),
sales_with_strings AS (
    SELECT
        swd.*,
        lower(c.c_email_address) AS email_lower,
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        concat(substring(c.c_first_name, 1, 1), '.', substring(c.c_last_name, 1, 1), '.') AS initials,
        i.i_product_name,
        i.i_item_desc,
        regexp_replace(i.i_product_name, '[AEIOUaeiou]', '*') AS masked_product_name,
        regexp_extract(i.i_item_id, '(\\d+)', 1) AS item_id_numeric,
        length(i.i_item_desc) AS desc_len,
        cardinality(regexp_extract_all(i.i_item_desc, '\\w+')) AS desc_word_cnt,
        regexp_replace(i.i_item_desc, '\\s+', '_') AS desc_underscored
    FROM sales_with_dims swd
    JOIN customer c ON swd.cust_sk = c.c_customer_sk
    JOIN item i ON swd.item_sk = i.i_item_sk
)
SELECT
    sws.d_year,
    sws.d_month_seq,
    sws.channel,
    sws.email_domain,
    count(*) AS order_cnt,
    sum(sws.net_paid) AS total_net_paid,
    avg(sws.quantity) AS avg_quantity,
    array_join(array_agg(DISTINCT sws.masked_product_name ORDER BY sws.masked_product_name), ', ') AS masked_product_list,
    length(array_join(array_agg(DISTINCT sws.masked_product_name ORDER BY sws.masked_product_name), ', ')) AS masked_product_list_len,
    max(sws.desc_len) AS max_desc_len,
    sum(sws.desc_word_cnt) AS total_desc_word_cnt,
    min(sws.email_lower) AS sample_email_lower,
    max(sws.full_name) AS sample_full_name
FROM sales_with_strings sws
WHERE sws.d_year = 2000
GROUP BY sws.d_year, sws.d_month_seq, sws.channel, sws.email_domain
HAVING count(*) > 5
ORDER BY total_net_paid DESC
LIMIT 100
