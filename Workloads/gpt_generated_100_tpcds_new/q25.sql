WITH joined_data AS (
    SELECT
        cc.cc_name,
        ca_refund.ca_city,
        ca_refund.ca_country,
        ca_refund.ca_location_type,
        CONCAT(cc.cc_name, ' - ', ca_refund.ca_city) AS center_city,
        SUBSTRING(ca_refund.ca_city FROM 1 FOR 3) AS city_prefix,
        CASE
            WHEN regexp_like(ca_refund.ca_address_id, '^AAAAAAA[AB]') THEN 'GroupA'
            ELSE 'Other'
        END AS address_group,
        cr.cr_net_loss,
        ws.ws_net_profit
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    LEFT JOIN web_sales ws
        ON cr.cr_order_number = ws.ws_order_number
       AND ws.ws_bill_addr_sk = ca_refund.ca_address_sk
    WHERE ca_refund.ca_country = 'United States'
      AND ca_refund.ca_location_type LIKE '%apartment%'
      AND regexp_like(ca_refund.ca_address_id, '^AAAAAAA[AB]')
)
SELECT
    center_city,
    ca_country,
    ca_location_type,
    city_prefix,
    address_group,
    SUM(cr_net_loss) AS total_net_loss,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count
FROM joined_data
GROUP BY CUBE (center_city, ca_country, ca_location_type, city_prefix, address_group)
ORDER BY total_net_loss DESC
LIMIT 100
