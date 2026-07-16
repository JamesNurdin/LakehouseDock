WITH unified_sales AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        s.s_store_id AS location_id,
        'store' AS channel
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    UNION ALL
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cc.cc_name,
        'catalog'
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        w.web_name,
        'web'
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    us.channel,
    SUM(us.net_paid) AS total_net_paid,
    SUM(us.net_profit) AS total_net_profit,
    COUNT(*) AS order_count,
    AVG(us.net_paid) AS avg_net_paid
FROM unified_sales us
JOIN date_dim d ON us.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year, d.d_month_seq, us.channel
ORDER BY total_net_paid DESC
LIMIT 100
