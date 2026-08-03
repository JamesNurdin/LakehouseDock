WITH cr AS (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        cr.cr_return_amount,
        r.r_reason_desc,
        word
    FROM (
        SELECT *
        FROM catalog_returns
        TABLESAMPLE BERNOULLI (10)
    ) cr
    JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    CROSS JOIN UNNEST(split(r.r_reason_desc, ' ')) AS t(word)
    WHERE cr.cr_return_amount > 100
),
ss AS (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        ss.ss_net_paid,
        CASE
            WHEN p.p_channel_email = 'Y' THEN 'Email'
            WHEN p.p_channel_tv = 'Y' THEN 'TV'
            ELSE 'Other'
        END AS promo_channel
    FROM (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ) ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_net_paid > 0
),
intersect_addresses AS (
    SELECT ca_address_id FROM cr
    INTERSECT
    SELECT ca_address_id FROM ss
),
full_agg AS (
    SELECT
        COALESCE(cr.ca_address_id, ss.ca_address_id) AS address_id,
        COALESCE(cr.ca_city, ss.ca_city) AS city,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM cr
    FULL OUTER JOIN ss
        ON cr.ca_address_id = ss.ca_address_id
    GROUP BY
        COALESCE(cr.ca_address_id, ss.ca_address_id),
        COALESCE(cr.ca_city, ss.ca_city)
),
final AS (
    SELECT
        address_id,
        city,
        total_return_amount,
        total_net_paid,
        'Aggregated' AS record_type
    FROM full_agg
    WHERE address_id IN (SELECT ca_address_id FROM intersect_addresses)
    UNION ALL
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        NULL AS total_return_amount,
        NULL AS total_net_paid,
        'IntersectOnly' AS record_type
    FROM intersect_addresses ia
    JOIN customer_address ca ON ia.ca_address_id = ca.ca_address_id
)
SELECT
    address_id,
    city,
    total_return_amount,
    total_net_paid,
    record_type
FROM final
ORDER BY city ASC, address_id
