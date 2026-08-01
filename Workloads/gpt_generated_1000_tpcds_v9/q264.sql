WITH first_group AS (
    SELECT
        w.web_site_id,
        w.web_name,
        w.web_mkt_class,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_mkt_class LIKE '%Wide%'
      AND w.web_rec_end_date = DATE '2000-08-15'
    GROUP BY w.web_site_id, w.web_name, w.web_mkt_class
    HAVING SUM(ws.ws_net_profit) > 1000
),
second_group AS (
    SELECT
        w.web_site_id,
        w.web_name,
        w.web_mkt_class,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_mkt_class LIKE '%Severe%'
      AND w.web_rec_end_date = DATE '2001-08-15'
    GROUP BY w.web_site_id, w.web_name, w.web_mkt_class
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT
    s.web_site_id,
    s.web_name,
    s.web_mkt_class,
    s.total_net_profit,
    s.total_sales,
    s.order_count,
    RANK() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        fg.web_site_id,
        fg.web_name,
        fg.web_mkt_class,
        fg.total_net_profit,
        fg.total_sales,
        fg.order_count
    FROM first_group fg
    UNION ALL
    SELECT
        sg.web_site_id,
        sg.web_name,
        sg.web_mkt_class,
        sg.total_net_profit,
        sg.total_sales,
        sg.order_count
    FROM second_group sg
) s
WHERE s.total_sales > 2000
ORDER BY profit_rank
LIMIT 100
