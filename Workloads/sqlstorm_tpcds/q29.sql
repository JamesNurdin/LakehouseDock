WITH
cust_emails AS (
    SELECT
        c.c_customer_sk,
        lower(c.c_email_address) AS email_lc,
        element_at(split(c.c_email_address, '@'), 2) AS email_domain,
        regexp_replace(c.c_email_address, '[^@]+@', '') AS domain_extracted,
        length(c.c_email_address) AS email_len,
        regexp_extract(c.c_email_address, '(?i)\\b([a-z0-9._%+-]+)@([a-z0-9.-]+)\\.(\\w{2,})\\b', 2) AS domain_part,
        regexp_extract(c.c_email_address, '(?i)\\b([a-z0-9._%+-]+)@([a-z0-9.-]+)\\.(\\w{2,})\\b', 3) AS tld,
        cardinality(split(c.c_email_address, '@')) AS email_parts_cnt
    FROM customer c
    WHERE c.c_email_address IS NOT NULL
),
cust_name_variants AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        lower(trim(c.c_first_name)) AS first_name_lc,
        upper(trim(c.c_last_name)) AS last_name_uc,
        concat_ws(' ', c.c_salutation, c.c_first_name, c.c_last_name) AS full_name,
        replace(concat_ws(' ', c.c_first_name, c.c_last_name), ' ', '_') AS name_underscored,
        substr(c.c_last_name, 1, 1) AS last_initial,
        length(c.c_first_name) AS first_len,
        length(c.c_last_name) AS last_len,
        cardinality(split(c.c_email_address, '@')) AS email_parts_cnt
    FROM customer c
),
call_center_address AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        cc.cc_zip,
        concat_ws(' ', cc.cc_street_number, cc.cc_street_name, cc.cc_street_type) AS street,
        concat_ws(', ', concat_ws(' ', cc.cc_street_number, cc.cc_street_name, cc.cc_street_type), cc.cc_city, cc.cc_state, cc.cc_zip) AS full_address,
        lower(cc.cc_name) AS name_lc,
        regexp_replace(cc.cc_name, '[^a-zA-Z]', '') AS name_alpha,
        length(cc.cc_name) AS name_len,
        replace(cc.cc_zip, '-', '') AS zip_nodash
    FROM call_center cc
),
sales_aggregated AS (
    SELECT
        'store' AS sales_channel,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_customer_sk AS cust_sk,
        sum(ss.ss_net_paid) AS total_net_paid,
        sum(ss.ss_quantity) AS total_quantity,
        count(*) AS txn_cnt,
        approx_percentile(ss.ss_net_paid, 0.5) AS median_net_paid,
        approx_percentile(ss.ss_quantity, 0.5) AS median_qty
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_customer_sk

    UNION ALL

    SELECT
        'catalog' AS sales_channel,
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        sum(cs.cs_net_paid) AS total_net_paid,
        sum(cs.cs_quantity) AS total_quantity,
        count(*) AS txn_cnt,
        approx_percentile(cs.cs_net_paid, 0.5) AS median_net_paid,
        approx_percentile(cs.cs_quantity, 0.5) AS median_qty
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk, cs.cs_bill_customer_sk

    UNION ALL

    SELECT
        'web' AS sales_channel,
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        sum(ws.ws_net_paid) AS total_net_paid,
        sum(ws.ws_quantity) AS total_quantity,
        count(*) AS txn_cnt,
        approx_percentile(ws.ws_net_paid, 0.5) AS median_net_paid,
        approx_percentile(ws.ws_quantity, 0.5) AS median_qty
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_bill_customer_sk
),
final_join AS (
    SELECT
        s.sales_channel,
        d.d_year,
        d.d_month_seq,
        cnv.c_first_name,
        cnv.c_last_name,
        cnv.first_name_lc,
        cnv.last_name_uc,
        cnv.full_name,
        cnv.name_underscored,
        cnv.last_initial,
        cnv.first_len,
        cnv.last_len,
        cnv.email_parts_cnt,
        ce.email_domain,
        ce.domain_extracted,
        ce.email_len,
        ce.domain_part,
        ce.tld,
        ca.name_alpha,
        ca.full_address,
        length(ca.full_address) AS address_len,
        s.total_net_paid,
        s.total_quantity,
        s.txn_cnt,
        s.median_net_paid,
        s.median_qty,
        concat_ws(' | ', s.sales_channel, CAST(s.total_net_paid AS varchar), concat_ws(' ', cnv.c_first_name, cnv.c_last_name)) AS composite_key,
        lower(concat_ws('_', cnv.c_first_name, cnv.c_last_name, coalesce(ce.email_domain, 'noemail'))) AS normalized_key,
        regexp_replace(concat_ws(' ', cnv.c_first_name, cnv.c_last_name), '\\s+', '-') AS hyphenated_name,
        substr(ca.full_address, 1, 30) AS address_prefix,
        coalesce(nullif(trim(ca.zip_nodash), ''), 'UNKNOWN') AS zip_clean
    FROM sales_aggregated s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN cust_name_variants cnv ON s.cust_sk = cnv.c_customer_sk
    LEFT JOIN cust_emails ce ON cnv.c_customer_sk = ce.c_customer_sk
    LEFT JOIN call_center_address ca ON ca.cc_call_center_sk = (SELECT max(cc_call_center_sk) FROM call_center)
)
SELECT
    sales_channel,
    d_year,
    d_month_seq,
    count(*) AS row_count,
    sum(total_net_paid) AS sum_net_paid,
    sum(total_quantity) AS sum_quantity,
    avg(total_net_paid) AS avg_net_paid,
    avg(total_quantity) AS avg_quantity,
    approx_percentile(total_net_paid, 0.9) AS p90_net_paid,
    max(address_len) AS max_address_len,
    min(address_len) AS min_address_len,
    count(DISTINCT normalized_key) AS distinct_normalized_keys,
    array_agg(DISTINCT email_domain) AS distinct_email_domains,
    array_agg(DISTINCT name_alpha) AS distinct_name_alpha,
    approx_percentile(first_len, 0.5) AS median_first_name_len,
    approx_percentile(last_len, 0.5) AS median_last_name_len,
    array_join(array_agg(DISTINCT last_initial), ', ') AS distinct_last_initials
FROM final_join
GROUP BY sales_channel, d_year, d_month_seq
ORDER BY sum_net_paid DESC
LIMIT 100
