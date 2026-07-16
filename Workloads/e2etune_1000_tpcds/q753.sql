WITH agg AS (
    SELECT
        s.web_site_sk,
        s.web_name,
        p.wp_type,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS total_transactions,
        AVG(ws.ws_quantity) AS avg_quantity,
        SUM(ws.ws_ext_discount_amt) / NULLIF(SUM(ws.ws_ext_list_price), 0) AS discount_rate
    FROM web_sales ws
    JOIN web_page p ON ws.ws_web_page_sk = p.wp_web_page_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE p.wp_image_count >= 4
      AND p.wp_autogen_flag = 'N'
      AND s.web_state = 'CA'
      AND ws.ws_sold_date_sk BETWEEN 2450810 AND 2450820
    GROUP BY s.web_site_sk, s.web_name, p.wp_type
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT
    agg.web_site_sk,
    agg.web_name,
    agg.wp_type,
    agg.total_net_profit,
    agg.total_net_paid,
    agg.total_transactions,
    agg.avg_quantity,
    agg.discount_rate,
    RANK() OVER (PARTITION BY agg.web_site_sk ORDER BY agg.total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY agg.total_net_profit DESC
LIMIT 100
