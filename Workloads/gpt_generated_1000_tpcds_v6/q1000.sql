WITH joined_data AS (
    SELECT
        d1.d_year AS year,
        i.i_category,
        w.w_state,
        cd.cd_gender,
        web_site.web_market_manager,
        reason.r_reason_desc,
        cs.cs_net_profit AS cs_net_profit,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        sr.sr_net_loss AS sr_net_loss
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    /* store_sales linked via item and customer */
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_customer_sk = c.c_customer_sk
    /* store_returns linked to store_sales and reason */
    JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
    JOIN reason ON sr.sr_reason_sk = reason.r_reason_sk
    /* web_sales linked via item, customer, web_page and web_site */
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    /* additional date & time joins for web_sales */
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    WHERE d1.d_year = 2000
        AND i.i_category = 'Electronics'
        AND w.w_state = 'CA'
        AND cd.cd_gender = 'M'
        AND web_site.web_market_manager = 'James Harris'
),
agg AS (
    SELECT
        year,
        i_category,
        w_state,
        SUM(cs_net_profit) AS total_catalog_profit,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(ws_net_profit) AS total_web_profit,
        SUM(sr_net_loss) AS total_return_loss
    FROM joined_data
    GROUP BY year, i_category, w_state
    HAVING SUM(cs_net_profit) > 10000
)
SELECT
    w_state,
    AVG(total_catalog_profit) AS avg_catalog_profit,
    AVG(total_store_profit) AS avg_store_profit,
    AVG(total_web_profit) AS avg_web_profit,
    AVG(total_return_loss) AS avg_return_loss
FROM agg
WHERE total_web_profit > 5000
GROUP BY w_state
ORDER BY avg_web_profit DESC
LIMIT 100
