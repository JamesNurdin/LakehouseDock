WITH filtered_store_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_addr_sk,
        sr.sr_reason_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_ship_cost,
        sr.sr_net_loss,
        sr.sr_returned_date_sk,
        ca.ca_address_sk,
        ca.ca_suite_number,
        ca.ca_city,
        ca.ca_state,
        ca.ca_location_type,
        s.s_store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        s.s_market_desc,
        s.s_suite_number,
        r.r_reason_desc
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        regexp_like(s.s_market_desc, '(?i)units|hours')
        AND s.s_suite_number LIKE 'Suite %'
        AND ca.ca_location_type = 'apartment'
        AND regexp_like(ca.ca_suite_number, '^Suite [0-9]+$')
        AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_refunded_addr_sk = ca.ca_address_sk
              AND wr.wr_reason_sk = sr.sr_reason_sk
        )
),
aggregated_returns AS (
    SELECT
        fr.s_store_name,
        fr.store_city,
        fr.store_state,
        fr.r_reason_desc,
        fr.sr_store_sk,
        fr.ca_suite_number,
        fr.ca_location_type,
        sum(fr.sr_return_quantity) AS total_return_quantity,
        sum(fr.sr_return_amt) AS total_return_amount,
        sum(fr.sr_return_ship_cost) AS total_ship_cost,
        sum(fr.sr_net_loss) AS total_net_loss
    FROM filtered_store_returns fr
    GROUP BY
        fr.s_store_name,
        fr.store_city,
        fr.store_state,
        fr.r_reason_desc,
        fr.sr_store_sk,
        fr.ca_suite_number,
        fr.ca_location_type
    HAVING sum(fr.sr_return_quantity) > 0
)
SELECT
    ar.s_store_name,
    ar.store_city,
    ar.store_state,
    concat(ar.store_city, ', ', ar.store_state) AS store_location,
    ar.r_reason_desc,
    ar.total_return_quantity,
    ar.total_return_amount,
    ar.total_ship_cost,
    ar.total_net_loss,
    CASE
        WHEN ar.total_net_loss > (SELECT avg(sr_net_loss) FROM store_returns) THEN 'Above Avg Loss'
        ELSE 'Below Avg Loss'
    END AS loss_category,
    regexp_extract(ar.ca_suite_number, '\\d+', 0) AS suite_number_digits,
    CASE
        WHEN ar.ca_location_type = 'apartment' THEN 'Apt'
        WHEN ar.ca_location_type = 'condo' THEN 'Condo'
        ELSE 'Other'
    END AS location_type_category,
    (SELECT max(s2.sr_returned_date_sk) FROM store_returns s2 WHERE s2.sr_store_sk = ar.sr_store_sk) AS last_return_date_sk
FROM aggregated_returns ar
ORDER BY ar.total_net_loss DESC
LIMIT 100
