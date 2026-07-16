WITH
customer_strings AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        lower(c.c_login) AS login_lower,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        reverse(concat(c.c_first_name, ' ', c.c_last_name)) AS name_rev,
        length(c.c_first_name) + length(c.c_last_name) AS name_len,
        length(regexp_replace(lower(concat(c.c_first_name, c.c_last_name)), '[^aeiou]', '')) AS vowel_count,
        regexp_extract(lower(c.c_email_address), '@([^@]+)', 1) AS email_domain,
        length(regexp_extract(lower(c.c_email_address), '@([^@]+)', 1)) AS domain_len,
        cardinality(split(regexp_extract(lower(c.c_email_address), '@([^@]+)', 1), '\\.')) AS domain_parts,
        replace(regexp_replace(lower(concat(c.c_first_name, ' ', c.c_last_name)), '[aeiou]', '*'), ' ', '_') AS encrypted_name,
        substr(c.c_first_name, 1, 1) AS first_initial,
        substr(c.c_last_name, 1, 1) AS last_initial,
        concat(substr(c.c_first_name, 1, 1), substr(c.c_last_name, 1, 1)) AS initials
    FROM
        customer c
    WHERE
        c.c_preferred_cust_flag = 'Y'
),
catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS c_customer_sk,
        sum(cs.cs_net_paid) AS catalog_sales,
        array_join(array_agg(DISTINCT i.i_category), ', ') AS catalog_categories,
        array_join(array_agg(DISTINCT i.i_item_desc), ', ') AS catalog_item_descs
    FROM
        catalog_sales cs
    JOIN
        item i ON i.i_item_sk = cs.cs_item_sk
    GROUP BY
        cs.cs_bill_customer_sk
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS c_customer_sk,
        sum(ws.ws_net_paid) AS web_sales,
        array_join(array_agg(DISTINCT wp.wp_type), '|') AS web_page_types,
        array_join(
            transform(
                array_distinct(
                    transform(
                        array_agg(DISTINCT wp.wp_url),
                        x -> regexp_extract(x, 'https?://([^/]+)', 1)
                    )
                ),
                y -> replace(y, 'www.', '')
            ),
            ', '
        ) AS visited_domains
    FROM
        web_sales ws
    JOIN
        web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    GROUP BY
        ws.ws_bill_customer_sk
)
SELECT
    cs.c_customer_id,
    cs.login_lower,
    cs.full_name,
    cs.name_rev,
    cs.name_len,
    cs.vowel_count,
    cs.email_domain,
    cs.domain_len,
    cs.domain_parts,
    cs.encrypted_name,
    cs.first_initial,
    cs.last_initial,
    cs.initials,
    ca.catalog_sales,
    wa.web_sales,
    coalesce(ca.catalog_sales, 0) + coalesce(wa.web_sales, 0) AS total_sales,
    ca.catalog_categories,
    ca.catalog_item_descs,
    wa.web_page_types,
    wa.visited_domains
FROM
    customer_strings cs
LEFT JOIN
    catalog_agg ca ON ca.c_customer_sk = cs.c_customer_sk
LEFT JOIN
    web_agg wa ON wa.c_customer_sk = cs.c_customer_sk
ORDER BY
    total_sales DESC
LIMIT 100
