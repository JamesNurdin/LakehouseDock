WITH filtered_call_center AS (
    SELECT
        cc_call_center_sk,
        concat(cc_name, ' - ', cc_city) AS cc_full_name,
        cc_suite_number
    FROM tpcds.call_center
    WHERE regexp_like(cc_suite_number, '^Suite[[:space:]][0-9]+$')
)
SELECT
    fcc.cc_full_name,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word_item_desc,
    CASE
        WHEN regexp_like(c.c_email_address, '^.*@example\\.com$') THEN 'ExampleDomain'
        ELSE 'OtherDomain'
    END AS email_domain_category
FROM filtered_call_center fcc
JOIN tpcds.catalog_sales cs ON cs.cs_call_center_sk = fcc.cc_call_center_sk
JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
WHERE d.d_year = 2001
  AND c.c_first_name LIKE 'J%'
GROUP BY
    fcc.cc_full_name,
    d.d_year,
    d.d_month_seq,
    regexp_extract(i.i_item_desc, '(\\w+)', 1),
    CASE
        WHEN regexp_like(c.c_email_address, '^.*@example\\.com$') THEN 'ExampleDomain'
        ELSE 'OtherDomain'
    END
ORDER BY total_sales DESC
LIMIT 100
