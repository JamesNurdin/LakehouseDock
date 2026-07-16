WITH sales AS (
    SELECT
        ws.*,
        i.i_product_name,
        p.p_promo_name,
        c.c_email_address,
        c.c_customer_id AS customer_id,
        d.d_year,
        wp.wp_url
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
),
url_metrics AS (
    SELECT
        *,
        regexp_extract(wp_url, '^(?:https?://)?([^/]+)', 1) AS domain,
        length(regexp_extract(wp_url, '^(?:https?://)?([^/]+)', 1)) AS domain_len,
        regexp_extract(regexp_extract(wp_url, '^(?:https?://)?([^/]+)', 1), '\\.([a-z]{2,})$', 1) AS tld,
        length(regexp_extract(regexp_extract(wp_url, '^(?:https?://)?([^/]+)', 1), '\\.([a-z]{2,})$', 1)) AS tld_len,
        reverse(regexp_extract(wp_url, '^(?:https?://)?([^/]+)', 1)) AS domain_rev,
        upper(regexp_extract(wp_url, '^(?:https?://)?([^/]+)', 1)) AS domain_upper,
        lower(regexp_extract(wp_url, '^(?:https?://)?([^/]+)', 1)) AS domain_lower,
        regexp_replace(regexp_extract(wp_url, '^(?:https?://)?([^/]+)', 1), '[AEIOUaeiou]', '') AS domain_no_vowels,
        length(regexp_extract(wp_url, '^(?:https?://)?([^/]+)', 1)) - length(regexp_replace(regexp_extract(wp_url, '^(?:https?://)?([^/]+)', 1), '[AEIOUaeiou]', '')) AS vowel_count,
        cardinality(split(regexp_replace(wp_url, '^([^/]+://)?[^/]+', ''), '/')) - 1 AS path_segment_count,
        substr(regexp_extract(wp_url, '^(?:https?://)?([^/]+)', 1), 1, 3) AS domain_prefix,
        regexp_extract(c_email_address, '@([^@]+)$', 1) AS email_domain,
        replace(i_product_name, ' ', '_') AS product_name_snake,
        substr(i_product_name, 1, 10) AS product_name_prefix,
        concat(i_product_name, ' - ', coalesce(p_promo_name, 'No Promo')) AS product_promo_combined
    FROM sales
),
aggregated AS (
    SELECT
        domain,
        domain_len,
        tld,
        tld_len,
        domain_rev,
        domain_upper,
        domain_lower,
        domain_no_vowels,
        vowel_count,
        path_segment_count,
        domain_prefix,
        email_domain,
        product_name_snake,
        product_name_prefix,
        product_promo_combined,
        sum(ws_ext_sales_price) AS total_sales,
        sum(ws_quantity) AS total_quantity,
        count(DISTINCT customer_id) AS distinct_customers,
        avg(ws_sales_price) AS avg_sales_price,
        max(ws_sales_price) AS max_sales_price,
        min(ws_sales_price) AS min_sales_price
    FROM url_metrics
    GROUP BY
        domain,
        domain_len,
        tld,
        tld_len,
        domain_rev,
        domain_upper,
        domain_lower,
        domain_no_vowels,
        vowel_count,
        path_segment_count,
        domain_prefix,
        email_domain,
        product_name_snake,
        product_name_prefix,
        product_promo_combined
    HAVING sum(ws_ext_sales_price) > 10000
)
SELECT
    domain,
    domain_len,
    tld,
    tld_len,
    domain_rev,
    domain_upper,
    domain_lower,
    domain_no_vowels,
    vowel_count,
    vowel_count * 1.0 / nullif(domain_len, 0) AS vowel_frac,
    path_segment_count,
    domain_prefix,
    email_domain,
    product_name_snake,
    product_name_prefix,
    product_promo_combined,
    total_sales,
    total_quantity,
    distinct_customers,
    avg_sales_price,
    max_sales_price,
    min_sales_price,
    row_number() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 10
