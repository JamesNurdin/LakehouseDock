WITH store_channel_profit AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        SUM(cs.cs_net_profit) AS cat_profit,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT cd.cd_demo_sk) AS distinct_demo_cnt,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_page_cnt
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE cd.cd_gender = 'F'
      AND cs.cs_coupon_amt > 1000.00
      AND s.s_rec_start_date >= DATE '2000-01-01'
      AND wp.wp_type = 'home'
    GROUP BY s.s_store_id, s.s_store_name
)
SELECT
    scp.s_store_id,
    scp.s_store_name,
    scp.cat_profit,
    scp.store_profit,
    scp.web_profit,
    (scp.cat_profit + scp.store_profit + scp.web_profit) AS total_profit,
    scp.distinct_demo_cnt,
    scp.distinct_page_cnt
FROM store_channel_profit scp
WHERE (scp.cat_profit + scp.store_profit + scp.web_profit) > (
    SELECT AVG(cat_profit + store_profit + web_profit)
    FROM store_channel_profit
)
ORDER BY total_profit DESC
LIMIT 100
