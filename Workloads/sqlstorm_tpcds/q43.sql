WITH customer_strings AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_email_address,
        lower(c_email_address) AS email_lower,
        regexp_extract(c_email_address, '@(.*)') AS email_domain,
        length(regexp_extract(c_email_address, '@(.*)')) AS domain_len,
        concat(c_first_name, ' ', c_last_name) AS full_name,
        concat(substr(c_first_name, 1, 1), '.', substr(c_last_name, 1, 1)) AS initials,
        reverse(concat(c_first_name, c_last_name)) AS name_reverse
    FROM customer
    WHERE c_email_address IS NOT NULL
),
sales_aggregated AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        sum(cs.cs_net_paid) AS total_net_paid,
        sum(cs.cs_quantity) AS total_quantity,
        count(DISTINCT cs.cs_order_number) AS distinct_orders,
        max(cs.cs_sold_date_sk) AS last_sold_date_sk
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk
),
item_strings AS (
    SELECT
        i_item_sk,
        i_product_name,
        lower(i_product_name) AS prod_name_lower,
        regexp_replace(i_product_name, '[^0-9]', '') AS prod_numeric_part,
        length(i_product_name) AS prod_len,
        substr(i_product_name, 1, 3) AS prod_prefix,
        reverse(i_product_name) AS prod_reverse,
        CASE
            WHEN i_product_name LIKE '%FREE%' THEN 'free'
            WHEN i_product_name LIKE '%DISCOUNT%' THEN 'discount'
            ELSE 'regular'
        END AS prod_category_flag
    FROM item
),
joined AS (
    SELECT
        cs.cust_sk,
        cs.total_net_paid,
        cs.total_quantity,
        cs.distinct_orders,
        i.i_item_sk,
        i.i_product_name,
        i.prod_category_flag,
        i.prod_numeric_part,
        i.prod_len,
        cs.last_sold_date_sk
    FROM sales_aggregated cs
    JOIN catalog_sales csale ON cs.cust_sk = csale.cs_bill_customer_sk
    JOIN item_strings i ON csale.cs_item_sk = i.i_item_sk
    WHERE i.prod_numeric_part <> ''
),
final AS (
    SELECT
        c.email_domain,
        c.domain_len,
        count(DISTINCT c.c_customer_sk) AS customers_in_domain,
        sum(j.total_net_paid) AS domain_total_sales,
        avg(j.total_quantity) AS avg_quantity_per_customer,
        max(j.last_sold_date_sk) AS latest_sold_date_sk,
        array_join(array_sort(array_agg(DISTINCT j.prod_category_flag)), ',') AS product_categories,
        array_join(array_sort(array_agg(DISTINCT substr(j.i_product_name, 1, 1))), '') AS product_initials,
        max(j.prod_len) AS longest_product_name_len,
        array_join(array_agg(DISTINCT j.prod_numeric_part), '-') AS numeric_parts_concat,
        reverse(c.email_domain) AS email_domain_rev,
        upper(c.email_domain) AS email_domain_upper
    FROM customer_strings c
    LEFT JOIN joined j ON c.c_customer_sk = j.cust_sk
    WHERE c.email_domain IS NOT NULL
    GROUP BY c.email_domain, c.domain_len
)
SELECT *
FROM final
ORDER BY domain_total_sales DESC
LIMIT 100
