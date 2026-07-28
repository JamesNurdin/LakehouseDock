WITH
    store_cte AS (
        SELECT
            sr.sr_reason_sk AS reason_sk,
            sr.sr_net_loss AS net_loss,
            ca.ca_street_type AS street_type,
            ca.ca_street_name AS street_name,
            r.r_reason_desc AS reason_desc
        FROM store_returns sr
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE regexp_like(ca.ca_street_name, '^Elm')
          AND ca.ca_city LIKE '%Ville%'
          AND EXISTS (
              SELECT 1 FROM reason r2
              WHERE r2.r_reason_sk = sr.sr_reason_sk
                AND regexp_like(r2.r_reason_desc, 'product')
          )
    ),
    web_cte AS (
        SELECT
            wr.wr_reason_sk AS reason_sk,
            wr.wr_net_loss AS net_loss,
            ca_ref.ca_street_type AS street_type,
            ca_ref.ca_street_name AS street_name,
            r.r_reason_desc AS reason_desc
        FROM web_returns wr
        JOIN web_sales ws
            ON wr.wr_order_number = ws.ws_order_number
           AND wr.wr_item_sk = ws.ws_item_sk
        JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE regexp_like(ca_ref.ca_street_name, '^Elm')
          AND ca_ref.ca_city LIKE '%Ville%'
          AND EXISTS (
              SELECT 1 FROM reason r2
              WHERE r2.r_reason_sk = wr.wr_reason_sk
                AND regexp_like(r2.r_reason_desc, 'product')
          )
    )
SELECT
    reason_desc,
    street_type,
    COUNT(*) AS return_count,
    SUM(net_loss) AS total_net_loss,
    CONCAT('Street ', street_type) AS street_type_label,
    regexp_extract(street_name, '(\\w+)$') AS street_name_suffix
FROM (
    SELECT * FROM store_cte
    UNION ALL
    SELECT * FROM web_cte
) combined
GROUP BY reason_desc, street_type, street_name
ORDER BY total_net_loss DESC
LIMIT 100
