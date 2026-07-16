SELECT
    customer_id,
    lower(substr(cust_initial_string, 1, 1)) AS cust_initial,
    upper(substr(email_domain, 1, 1)) AS domain_initial,
    sum(sales_amount) AS total_sales,
    count(*) AS num_transactions,
    avg(product_name_len) AS avg_product_name_len,
    avg(num_vowels) AS avg_vowels_in_item_desc,
    avg(num_words) AS avg_words_in_item_desc,
    sum(promotion_match) AS promo_match_count,
    max(full_string_length) AS max_combined_string_len
FROM (
    SELECT
        c.c_customer_id AS customer_id,
        c.c_first_name || ' ' || c.c_last_name AS cust_initial_string,
        substr(c.c_email_address, strpos(c.c_email_address, '@') + 1) AS email_domain,
        i.i_product_name,
        i.i_item_desc,
        p.p_promo_name,
        ss.ss_net_paid AS sales_amount,
        length(regexp_replace(lower(i.i_product_name), '[^a-z]', '')) AS product_name_len,
        length(regexp_replace(lower(i.i_item_desc), '[^aeiou]', '')) AS num_vowels,
        cardinality(split(regexp_replace(lower(i.i_item_desc), '[^a-z ]', ''), ' ')) AS num_words,
        CASE WHEN p.p_promo_name IS NOT NULL AND regexp_like(lower(p.p_promo_name), '.*discount.*') THEN 1 ELSE 0 END AS promotion_match,
        length(concat_ws(' ',
            c.c_first_name,
            c.c_last_name,
            substr(c.c_email_address, strpos(c.c_email_address, '@') + 1),
            i.i_product_name,
            i.i_item_desc,
            coalesce(p.p_promo_name, '')
        )) AS full_string_length
    FROM
        customer c
        JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk

    UNION ALL

    SELECT
        c.c_customer_id AS customer_id,
        c.c_first_name || ' ' || c.c_last_name AS cust_initial_string,
        substr(c.c_email_address, strpos(c.c_email_address, '@') + 1) AS email_domain,
        i.i_product_name,
        i.i_item_desc,
        p.p_promo_name,
        ws.ws_net_paid AS sales_amount,
        length(regexp_replace(lower(i.i_product_name), '[^a-z]', '')) AS product_name_len,
        length(regexp_replace(lower(i.i_item_desc), '[^aeiou]', '')) AS num_vowels,
        cardinality(split(regexp_replace(lower(i.i_item_desc), '[^a-z ]', ''), ' ')) AS num_words,
        CASE WHEN p.p_promo_name IS NOT NULL AND regexp_like(lower(p.p_promo_name), '.*discount.*') THEN 1 ELSE 0 END AS promotion_match,
        length(concat_ws(' ',
            c.c_first_name,
            c.c_last_name,
            substr(c.c_email_address, strpos(c.c_email_address, '@') + 1),
            i.i_product_name,
            i.i_item_desc,
            coalesce(p.p_promo_name, '')
        )) AS full_string_length
    FROM
        customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
) t
GROUP BY
    customer_id,
    cust_initial_string,
    email_domain
HAVING
    sum(sales_amount) > 1000
ORDER BY
    total_sales DESC
LIMIT 50
