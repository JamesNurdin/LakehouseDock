WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk   AS web_site_sk,
        ws.ws_bill_addr_sk  AS bill_addr_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*)               AS sales_cnt
    FROM tpcds.web_sales ws
    WHERE ws.ws_net_profit > 0
    GROUP BY ws.ws_web_site_sk, ws.ws_bill_addr_sk
)
SELECT
    wsit.web_site_id,
    ca.ca_city,
    wsit.web_mkt_id,
    CONCAT(wsit.web_site_id, '-', ca.ca_city) AS site_city_key,
    SUM(sa.total_profit)                         AS market_city_profit,
    CASE
        WHEN SUM(sa.total_profit) > (
            SELECT AVG(total_profit) FROM sales_agg
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END                                          AS profit_category,
    COUNT(*)                                     AS num_groups,
    REGEXP_EXTRACT(wsit.web_site_id, '(\\d+)$') AS site_numeric_suffix
FROM sales_agg sa
JOIN tpcds.web_site wsit
    ON sa.web_site_sk = wsit.web_site_sk
JOIN tpcds.customer_address ca
    ON sa.bill_addr_sk = ca.ca_address_sk
WHERE regexp_like(wsit.web_site_id, '^A{5,}.*$')          -- site id starts with at least 5 "A"s
  AND ca.ca_city LIKE 'F%'                               -- city begins with "F"
  AND EXISTS (
        SELECT 1
        FROM tpcds.web_sales ws2
        WHERE ws2.ws_web_site_sk = wsit.web_site_sk
          AND ws2.ws_quantity > 5
    )
GROUP BY wsit.web_site_id, ca.ca_city, wsit.web_mkt_id, wsit.web_site_id, ca.ca_city
HAVING COUNT(*) >= 5
ORDER BY market_city_profit DESC
LIMIT 100
