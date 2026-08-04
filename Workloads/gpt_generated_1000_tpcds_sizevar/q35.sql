WITH all_segments AS (
    SELECT
        ws.ws_web_site_sk AS site_sk,
        w.web_site_id   AS site_id,
        SUM(ws.ws_net_profit) AS profit,
        'HighCost'      AS segment
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_ext_wholesale_cost > 1000
      AND w.web_country = 'United States'
    GROUP BY ws.ws_web_site_sk, w.web_site_id

    UNION ALL

    SELECT
        ws.ws_web_site_sk,
        w.web_site_id,
        SUM(ws.ws_net_profit),
        'PromoSpecial'
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_promo_sk IN (1035, 197)
      AND w.web_country <> 'United States'
    GROUP BY ws.ws_web_site_sk, w.web_site_id

    UNION ALL

    SELECT
        ws.ws_web_site_sk,
        w.web_site_id,
        SUM(ws.ws_net_profit),
        'LowQuantity'
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_quantity < 5
    GROUP BY ws.ws_web_site_sk, w.web_site_id
)
,
small_dim AS (
    SELECT DISTINCT w.web_state AS state
    FROM web_site w
    WHERE w.web_state IS NOT NULL
    LIMIT 5
)
SELECT
    s.segment,
    s.site_id,
    s.profit,
    d.state,
    (
        SELECT COUNT(*)
        FROM web_sales ws_inner
        WHERE ws_inner.ws_web_site_sk = s.site_sk
    ) AS total_sales_per_site
FROM all_segments s
CROSS JOIN small_dim d
WHERE s.site_id NOT IN (
    SELECT w2.web_site_id
    FROM web_site w2
    WHERE w2.web_state = 'CA'
)
ORDER BY s.profit DESC, s.segment
