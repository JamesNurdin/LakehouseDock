WITH sales_top_per_site AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ws.ws_promo_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE w.web_street_name LIKE '%Ridge%'
      AND p.p_channel_catalog = 'N'
)
SELECT
    'sale' AS activity,
    w.web_name,
    s.ws_order_number,
    s.ws_net_paid,
    s.ws_quantity,
    s.ws_sold_date_sk
FROM sales_top_per_site s
JOIN web_site w ON s.ws_web_site_sk = w.web_site_sk
WHERE s.rn = 1

UNION ALL

SELECT
    'return' AS activity,
    w2.web_name,
    r.wr_order_number,
    r.wr_return_amt,
    r.wr_return_quantity,
    r.wr_returned_date_sk
FROM web_returns r
JOIN web_sales ws2 ON r.wr_order_number = ws2.ws_order_number
JOIN web_site w2 ON ws2.ws_web_site_sk = w2.web_site_sk
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_promo_sk = ws2.ws_promo_sk
      AND p2.p_purpose = 'Unknown'
)
  AND w2.web_state = 'CA'
ORDER BY activity, web_name
