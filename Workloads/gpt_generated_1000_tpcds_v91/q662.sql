WITH
    refunded_returns AS (
        SELECT
            wr.wr_order_number,
            wr.wr_net_loss,
            wr.wr_return_amt,
            wr.wr_reason_sk,
            ca.ca_address_sk,
            ca.ca_street_name,
            ca.ca_street_number,
            ca.ca_zip,
            reason.r_reason_id,
            reason.r_reason_desc,
            wp.wp_url,
            wp.wp_type
        FROM web_returns wr
        JOIN customer_address ca
            ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        JOIN reason
            ON wr.wr_reason_sk = reason.r_reason_sk
        JOIN web_page wp
            ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE
            regexp_like(ca.ca_street_name, '^(Elm|Maple).*')
            AND ca.ca_location_type LIKE '%apartment%'
            AND wp.wp_url LIKE 'http%://%/product/%'
    ),
    high_loss_orders AS (
        SELECT wr_order_number
        FROM refunded_returns
        WHERE wr_net_loss > 1000
    ),
    other_reason_orders AS (
        SELECT wr.wr_order_number
        FROM web_returns wr
        WHERE wr.wr_reason_sk = 1
    ),
    excluded_orders AS (
        SELECT wr_order_number FROM high_loss_orders
        EXCEPT
        SELECT wr_order_number FROM other_reason_orders
    )
SELECT
    fr.r_reason_id,
    fr.r_reason_desc,
    COUNT(DISTINCT fr.wr_order_number) AS num_returns,
    SUM(fr.wr_net_loss) AS total_net_loss,
    AVG(fr.wr_return_amt) AS avg_return_amount,
    regexp_extract(fr.ca_zip, '^([0-9]{3})', 1) AS zip_prefix,
    concat(fr.ca_street_name, ' ', fr.ca_street_number) AS full_street,
    (SELECT MAX(wr2.wr_return_amt)
     FROM web_returns wr2
     WHERE wr2.wr_reason_sk = fr.wr_reason_sk) AS max_return_amount_for_reason
FROM refunded_returns fr
WHERE fr.wr_order_number NOT IN (SELECT wr_order_number FROM excluded_orders)
GROUP BY
    fr.r_reason_id,
    fr.r_reason_desc,
    regexp_extract(fr.ca_zip, '^([0-9]{3})', 1),
    concat(fr.ca_street_name, ' ', fr.ca_street_number),
    fr.wr_reason_sk
ORDER BY total_net_loss DESC
LIMIT 100
