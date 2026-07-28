WITH bill AS (
    SELECT
        ca.ca_state,
        CASE 
            WHEN ws.ws_list_price >= 100 THEN 'high'
            WHEN ws.ws_list_price >= 50  THEN 'medium'
            ELSE 'low'
        END AS price_category,
        CONCAT(ca.ca_state, '-', CASE 
            WHEN ws.ws_list_price >= 100 THEN 'high'
            WHEN ws.ws_list_price >= 50  THEN 'medium'
            ELSE 'low'
        END) AS state_price_key,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(*) AS cnt,
        REGEXP_EXTRACT(ca.ca_street_name, '\\d+', 0) AS street_number_extracted
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_ext_tax > 30
      AND ca.ca_street_name LIKE '%Sixth%'
    GROUP BY ca.ca_state,
             CASE 
                 WHEN ws.ws_list_price >= 100 THEN 'high'
                 WHEN ws.ws_list_price >= 50  THEN 'medium'
                 ELSE 'low'
             END,
             REGEXP_EXTRACT(ca.ca_street_name, '\\d+', 0)
),
ship AS (
    SELECT
        ca.ca_state,
        CASE 
            WHEN ws.ws_list_price >= 100 THEN 'high'
            WHEN ws.ws_list_price >= 50  THEN 'medium'
            ELSE 'low'
        END AS price_category,
        CONCAT(ca.ca_state, '-', CASE 
            WHEN ws.ws_list_price >= 100 THEN 'high'
            WHEN ws.ws_list_price >= 50  THEN 'medium'
            ELSE 'low'
        END) AS state_price_key,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(*) AS cnt,
        REGEXP_EXTRACT(ca.ca_street_name, '\\d+', 0) AS street_number_extracted
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_address ca
        ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE ws.ws_ext_tax > 30
      AND REGEXP_LIKE(ca.ca_street_name, '^College')
    GROUP BY ca.ca_state,
             CASE 
                 WHEN ws.ws_list_price >= 100 THEN 'high'
                 WHEN ws.ws_list_price >= 50  THEN 'medium'
                 ELSE 'low'
             END,
             REGEXP_EXTRACT(ca.ca_street_name, '\\d+', 0)
)
SELECT
    ca_state,
    price_category,
    state_price_key,
    total_tax,
    cnt,
    street_number_extracted
FROM bill
UNION ALL
SELECT
    ca_state,
    price_category,
    state_price_key,
    total_tax,
    cnt,
    street_number_extracted
FROM ship
ORDER BY ca_state, total_tax DESC
