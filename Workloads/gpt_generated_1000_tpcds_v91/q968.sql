WITH joined_data AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_sales_price,
        cd.cd_purchase_estimate,
        t.t_hour,
        wp.wp_type,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        web_site.web_site_id,
        web_site.web_name,
        web_site.web_mkt_class
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
    WHERE
        t.t_hour BETWEEN 9 AND 18
        AND cd.cd_purchase_estimate >= 5000
        AND web_site.web_mkt_class LIKE '%Broad%'
        AND ws.ws_quantity > 2
        AND ws.ws_net_profit > 0
        AND ws.ws_net_paid > (SELECT AVG(ws2.ws_net_paid) FROM web_sales ws2)
),
agg_data AS (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        web_site_id,
        web_name,
        web_mkt_class,
        ws_web_site_sk,
        SUM(ws_net_paid) AS total_paid,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        AVG(ws_quantity) AS avg_quantity
    FROM joined_data
    GROUP BY
        c_customer_id,
        c_first_name,
        c_last_name,
        web_site_id,
        web_name,
        web_mkt_class,
        ws_web_site_sk
    HAVING
        SUM(ws_net_profit) > 1000
)
SELECT
    ad.c_customer_id,
    ad.c_first_name,
    ad.c_last_name,
    ad.web_site_id,
    ad.web_name,
    ad.web_mkt_class,
    ad.total_paid,
    ad.total_profit,
    ad.order_count,
    ad.avg_quantity,
    CASE
        WHEN ad.total_profit > 10000 THEN 'High'
        WHEN ad.total_profit > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY ad.web_mkt_class ORDER BY ad.total_profit DESC) AS profit_rank_in_market,
    SUM(ad.total_paid) OVER (PARTITION BY ad.web_mkt_class ORDER BY ad.total_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_paid_in_market,
    (SELECT MAX(ws3.ws_sales_price)
     FROM web_sales ws3
     WHERE ws3.ws_web_site_sk = ad.ws_web_site_sk) AS max_sales_price_for_site
FROM agg_data ad
ORDER BY ad.total_profit DESC
LIMIT 100
