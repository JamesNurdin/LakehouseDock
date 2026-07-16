WITH store_return_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_addr_sk,
        sr.sr_returned_date_sk,
        d_ret.d_year AS return_year,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_ticket_cnt
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    GROUP BY
        sr.sr_store_sk,
        sr.sr_addr_sk,
        sr.sr_returned_date_sk,
        d_ret.d_year
)

SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    ca.ca_city,
    ca.ca_state,
    d_closure.d_year AS store_closed_year,
    agg.return_year,
    agg.total_net_loss,
    agg.avg_return_qty,
    agg.distinct_ticket_cnt,
    AVG(wp.wp_image_count) AS avg_image_count,
    DATE_DIFF('day', d_creation.d_date, d_access.d_date) AS days_between_creation_and_access
FROM store_return_agg agg
JOIN store s
    ON agg.sr_store_sk = s.s_store_sk
JOIN customer_address ca
    ON agg.sr_addr_sk = ca.ca_address_sk
JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
JOIN date_dim d_creation
    ON agg.sr_returned_date_sk = d_creation.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE agg.return_year BETWEEN 2015 AND 2020
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    ca.ca_city,
    ca.ca_state,
    d_closure.d_year,
    agg.return_year,
    agg.total_net_loss,
    agg.avg_return_qty,
    agg.distinct_ticket_cnt,
    d_creation.d_date,
    d_access.d_date
ORDER BY agg.total_net_loss DESC
LIMIT 100
