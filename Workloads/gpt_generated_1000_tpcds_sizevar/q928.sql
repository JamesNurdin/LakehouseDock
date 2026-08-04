WITH filtered_address AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, ca_county, ca_street_type, ca_gmt_offset, ca_location_type
    FROM customer_address
    WHERE ca_state = 'CA'
      AND ca_county IN ('Potter County', 'Washington County')
      AND ca_street_type IN ('Blvd', 'Road')
      AND ca_gmt_offset BETWEEN -5.00 AND 5.00
      AND ca_location_type = 'RESIDENTIAL'
)
SELECT
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    ca.ca_city,
    ca.ca_state,
    wp.wp_type,
    ss.ss_net_paid,
    COALESCE(wr.wr_return_amt, 0) AS return_amount,
    (ss.ss_net_paid - COALESCE(wr.wr_return_amt, 0)) AS net_after_return,
    CASE
        WHEN ss.ss_net_paid - COALESCE(wr.wr_return_amt, 0) > 1000 THEN 'HIGH'
        WHEN ss.ss_net_paid - COALESCE(wr.wr_return_amt, 0) > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY (ss.ss_net_paid - COALESCE(wr.wr_return_amt, 0)) DESC) AS state_rank,
    SUM(ss.ss_net_paid) OVER (PARTITION BY ca.ca_city ORDER BY ss.ss_sold_date_sk ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS moving_sum_4_sales,
    (
        SELECT MAX(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_refunded_addr_sk = ca.ca_address_sk
    ) AS max_return_for_addr
FROM filtered_address ca
FULL OUTER JOIN store_sales ss
    ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
LEFT JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
WHERE
    ss.ss_sold_date_sk BETWEEN 2450800 AND 2450900
    AND ss.ss_quantity > 1
    AND ss.ss_net_paid > 50
    AND (wr.wr_return_amt IS NULL OR wr.wr_return_amt < 200)
    AND wp.wp_type = 'order'
ORDER BY net_after_return DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
