WITH ws_filtered AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_addr_sk,
        ws.ws_web_site_sk
    FROM web_sales ws
    WHERE ws.ws_net_paid_inc_tax > 500
      AND ws.ws_ext_tax IS NOT NULL
)
SELECT
    d.d_year,
    we.web_mkt_class,
    SUM(ws.ws_net_paid_inc_tax) AS total_paid,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS order_cnt,
    COUNT(DISTINCT REGEXP_EXTRACT(ca.ca_suite_number, '\\d+')) AS distinct_suite_cnt
FROM ws_filtered ws
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE REGEXP_LIKE(we.web_mkt_class, '(?i)Leaders|Labour|Continuous')
  AND ca.ca_suite_number LIKE 'Suite %'
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = ws.ws_item_sk
          AND sr.sr_customer_sk = ws.ws_bill_customer_sk
          AND sr.sr_returned_date_sk >= ws.ws_sold_date_sk
    )
GROUP BY ROLLUP (d.d_year, we.web_mkt_class)
ORDER BY total_paid DESC
LIMIT 100
