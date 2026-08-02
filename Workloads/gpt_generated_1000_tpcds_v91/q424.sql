WITH store_agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        CAST('Store' AS varchar) AS channel,
        map(
            ARRAY['net_paid', 'return_loss'],
            ARRAY[
                SUM(ss.ss_net_paid),
                SUM(COALESCE(sr.sr_net_loss, 0))
            ]
        ) AS metrics
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    WHERE c.c_preferred_cust_flag = 'Y'
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_promo_id, p.p_promo_name
),
web_agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        CAST('Web' AS varchar) AS channel,
        map(
            ARRAY['net_paid'],
            ARRAY[
                SUM(ws.ws_net_paid)
            ]
        ) AS metrics
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND p.p_discount_active = 'Y'
      AND wsite.web_site_sk IN (
          SELECT web_site_sk
          FROM web_site
          WHERE web_mkt_class LIKE '%New%'
      )
    GROUP BY p.p_promo_id, p.p_promo_name
)
SELECT
    s.promo_id,
    s.promo_name,
    s.channel,
    m.metric_key AS metric,
    m.metric_value AS value,
    (SELECT MAX(p_start.p_start_date_sk) FROM promotion p_start WHERE p_start.p_discount_active = 'Y') AS max_start_date_sk
FROM store_agg s
CROSS JOIN UNNEST(s.metrics) AS m(metric_key, metric_value)

UNION ALL

SELECT
    w.promo_id,
    w.promo_name,
    w.channel,
    m.metric_key AS metric,
    m.metric_value AS value,
    (SELECT MAX(p_start.p_start_date_sk) FROM promotion p_start WHERE p_start.p_discount_active = 'Y') AS max_start_date_sk
FROM web_agg w
CROSS JOIN UNNEST(w.metrics) AS m(metric_key, metric_value)

ORDER BY promo_id, channel, metric
LIMIT 100
