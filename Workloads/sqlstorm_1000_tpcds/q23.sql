WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        lower(c.c_email_address) AS email_lc,
        split(lower(c.c_email_address), '@')[2] AS email_domain,
        i.i_item_id,
        i.i_product_name,
        substr(i.i_product_name, 1, 5) AS product_prefix,
        regexp_replace(i.i_item_desc, '\\W+', ' ') AS clean_desc,
        length(i.i_item_desc) AS desc_len,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND regexp_like(lower(c.c_email_address), '.*@(gmail|yahoo|hotmail)\\.com')
)
SELECT
    d_year,
    d_month_seq,
    email_domain,
    count(DISTINCT c_customer_id) AS uniq_customers,
    sum(ws_sales_price) AS total_sales,
    avg(ws_sales_price) AS avg_sales_price,
    sum(ws_quantity) AS total_quantity,
    avg(desc_len) AS avg_desc_len,
    approx_percentile(ws_net_paid, 0.5) AS median_net_paid,
    concat('Domain_', email_domain) AS domain_tag,
    replace(product_prefix, ' ', '_') AS product_tag,
    regexp_replace(clean_desc, '\\s+', '_') AS clean_desc_underscored,
    array_join(regexp_split(clean_desc, '\\s+'), ',') AS clean_desc_csv,
    translate(clean_desc, 'AEIOUaeiou', '----------') AS clean_desc_no_vowels,
    reverse(clean_desc) AS reversed_desc,
    array_agg(DISTINCT substr(i_product_name, 1, 3)) AS product_name_prefixes
FROM base
GROUP BY
    d_year,
    d_month_seq,
    email_domain,
    product_prefix,
    clean_desc
ORDER BY total_sales DESC
LIMIT 100
