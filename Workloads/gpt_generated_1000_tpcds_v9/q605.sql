WITH address_details AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_location_type,
        regexp_extract(ca.ca_address_id, '([A-Z]+)$') AS address_suffix,
        addr_num,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_address_sk ORDER BY addr_num) AS addr_num_seq
    FROM
        customer_address ca
        CROSS JOIN UNNEST(regexp_extract_all(ca.ca_address_id, '[0-9]+')) AS t(addr_num)
    WHERE
        regexp_like(ca.ca_city, '.*view$')
        OR ca.ca_city LIKE 'Lake%'
),

sales_agg AS (
    SELECT
        ss_addr_sk,
        total_net_paid,
        total_tax,
        sales_cnt,
        max_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss_addr_sk ORDER BY total_net_paid DESC) AS sales_rank
    FROM (
        SELECT
            ss.ss_addr_sk,
            SUM(ss.ss_net_paid) AS total_net_paid,
            SUM(ss.ss_ext_tax) AS total_tax,
            COUNT(*) AS sales_cnt,
            MAX(ss.ss_net_paid) AS max_net_paid
        FROM store_sales ss
        WHERE ss.ss_ext_tax > 10.0
        GROUP BY ss.ss_addr_sk
    ) agg
)

SELECT DISTINCT
    CONCAT(ad.ca_city, ', ', ad.ca_state) AS city_state,
    ad.address_suffix,
    sa.total_net_paid,
    SUM(sa.total_net_paid) OVER (PARTITION BY ad.ca_state) AS state_total_net_paid,
    sa.sales_cnt,
    sa.sales_rank,
    ad.addr_num_seq,
    'full_join' AS source
FROM address_details ad
FULL OUTER JOIN sales_agg sa
    ON ad.ca_address_sk = sa.ss_addr_sk

UNION DISTINCT

SELECT DISTINCT
    CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
    regexp_extract(ca.ca_address_id, '([A-Z]+)$') AS address_suffix,
    NULL AS total_net_paid,
    NULL AS state_total_net_paid,
    0 AS sales_cnt,
    NULL AS sales_rank,
    NULL AS addr_num_seq,
    'address_only' AS source
FROM customer_address ca
WHERE
    regexp_like(ca.ca_city, '.*view$')
    OR ca.ca_city LIKE 'Lake%'

LIMIT 100
