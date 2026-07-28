WITH base_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid_inc_tax,
        ss.ss_quantity,
        ca.ca_address_sk,
        ca.ca_county,
        ca.ca_city,
        ca.ca_zip,
        cd.cd_demo_sk,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        ca.ca_street_number,
        ca.ca_street_name,
        ca.ca_street_type,
        regexp_extract(ca.ca_city, '([A-Za-z]+)', 1) AS city_first_word,
        addr.full_address,
        addr.address_len
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN LATERAL (
        SELECT
            concat(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
            length(concat(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type)) AS address_len
    ) AS addr
    WHERE ca.ca_county LIKE '%County'
      AND ca.ca_zip LIKE '9%'
      AND regexp_like(ca.ca_city, '^[A-Z][a-z]+$')
)
SELECT group_key,
       total_sales,
       distinct_tickets
FROM (
    SELECT
        ca_county AS group_key,
        sum(ss_net_paid_inc_tax) AS total_sales,
        count(DISTINCT ss_ticket_number) AS distinct_tickets
    FROM base_sales
    GROUP BY ca_county
    HAVING sum(ss_net_paid_inc_tax) > 10000

    UNION

    SELECT
        cd_credit_rating AS group_key,
        sum(ss_net_paid_inc_tax) AS total_sales,
        count(DISTINCT ss_ticket_number) AS distinct_tickets
    FROM base_sales
    GROUP BY cd_credit_rating
    HAVING sum(ss_net_paid_inc_tax) > 10000
) AS combined_results
ORDER BY total_sales DESC
