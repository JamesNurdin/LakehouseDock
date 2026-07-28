WITH sales_site AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_order_number,
        s.web_name,
        s.web_city,
        s.web_manager
    FROM web_sales ws
    JOIN web_site s
        ON ws.ws_web_site_sk = s.web_site_sk
    WHERE ws.ws_coupon_amt > 1000
      AND ws.ws_ext_discount_amt < 5000
      AND ws.ws_quantity >= 2
      AND s.web_manager IN ('Robert Arnold', 'Charles Parker')
      AND s.web_city <> 'Harmony'
),
agg_site AS (
    SELECT
        ss.ws_web_site_sk,
        ss.web_name,
        ss.web_city,
        ss.web_manager,
        SUM(ss.ws_net_paid) AS total_net_paid,
        SUM(ss.ws_net_profit) AS total_net_profit,
        COUNT(ss.ws_order_number) AS order_cnt
    FROM sales_site ss
    GROUP BY ss.ws_web_site_sk, ss.web_name, ss.web_city, ss.web_manager
    HAVING SUM(ss.ws_net_paid) > 50000
       AND COUNT(ss.ws_order_number) >= 5
)
SELECT
    a.ws_web_site_sk,
    a.web_name,
    a.web_city,
    a.web_manager,
    a.total_net_paid,
    a.total_net_profit,
    a.order_cnt,
    RANK() OVER (ORDER BY a.total_net_profit DESC) AS profit_rank
FROM agg_site a
ORDER BY profit_rank
LIMIT 100
