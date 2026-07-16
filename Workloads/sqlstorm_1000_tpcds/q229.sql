WITH
sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        COALESCE(SUM(cs.cs_net_paid), 0) AS cat_net_paid,
        COALESCE(SUM(ss.ss_net_paid), 0) AS store_net_paid,
        COALESCE(SUM(ws.ws_net_paid), 0) AS web_net_paid
    FROM item i
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_product_name, i.i_item_desc, i.i_category, i.i_brand
),
product_strings AS (
    SELECT
        sa.i_item_sk,
        sa.i_product_name,
        LOWER(REGEXP_REPLACE(sa.i_product_name, '\\s+', '_')) AS normalized_name,
        SUBSTR(sa.i_product_name, 1, 10) AS name_prefix,
        LENGTH(sa.i_product_name) AS name_len,
        REVERSE(sa.i_product_name) AS name_reversed,
        CASE WHEN REGEXP_LIKE(sa.i_product_name, '\\d') THEN 1 ELSE 0 END AS contains_digit_flag,
        sa.i_item_desc,
        LOWER(REGEXP_REPLACE(sa.i_item_desc, '[^a-z0-9 ]', '')) AS cleaned_desc
    FROM sales_agg sa
),
desc_tokens AS (
    SELECT
        ps.i_item_sk,
        ARRAY_DISTINCT(FILTER(SPLIT(ps.cleaned_desc, ' '), x -> x <> '')) AS distinct_words
    FROM product_strings ps
),
item_customer_sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        SUM(cs.cs_net_paid) AS cust_item_net
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_bill_customer_sk
),
top_customer_per_item AS (
    SELECT
        cs_item_sk,
        cs_bill_customer_sk,
        cust_item_net,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cust_item_net DESC) AS rn
    FROM item_customer_sales
),
top_customer AS (
    SELECT
        tci.cs_item_sk,
        c.c_customer_sk,
        LOWER(c.c_last_name) || '_' || LOWER(c.c_first_name) AS cust_key,
        REGEXP_REPLACE(LOWER(c.c_email_address), '@.*', '@***') AS masked_email,
        ca.ca_city,
        ca.ca_state,
        CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number,
                  ca.ca_city, ca.ca_state, ca.ca_zip, ca.ca_country) AS full_address
    FROM top_customer_per_item tci
    JOIN customer c ON tci.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE tci.rn = 1
),
final AS (
    SELECT
        sa.i_item_sk,
        sa.i_product_name,
        ps.normalized_name,
        ps.name_prefix,
        ps.name_len,
        ps.name_reversed,
        ps.contains_digit_flag,
        CARDINALITY(dt.distinct_words) AS distinct_word_count,
        ARRAY_JOIN(dt.distinct_words, '|') AS word_bag,
        ELEMENT_AT(dt.distinct_words, 1) AS first_distinct_word,
        sa.i_category,
        sa.i_brand,
        (sa.cat_net_paid + sa.store_net_paid + sa.web_net_paid) AS total_sales,
        ROUND((sa.cat_net_paid + sa.store_net_paid + sa.web_net_paid) / NULLIF(sa.cat_net_paid, 0), 2) AS sales_vs_cat_factor,
        RANK() OVER (PARTITION BY sa.i_category ORDER BY (sa.cat_net_paid + sa.store_net_paid + sa.web_net_paid) DESC) AS category_sales_rank,
        tc.cust_key,
        tc.masked_email,
        CONCAT_WS(', ', tc.ca_city, tc.ca_state) AS top_customer_city_state,
        tc.full_address
    FROM sales_agg sa
    JOIN product_strings ps ON sa.i_item_sk = ps.i_item_sk
    JOIN desc_tokens dt ON ps.i_item_sk = dt.i_item_sk
    LEFT JOIN top_customer tc ON sa.i_item_sk = tc.cs_item_sk
)
SELECT *
FROM final
WHERE total_sales > 5000
ORDER BY total_sales DESC
LIMIT 100
