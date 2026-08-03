WITH base AS (
    SELECT
        s.s_store_name,
        d.d_year,
        cd.cd_gender,
        cc.cc_market_manager,
        wp.wp_char_count,
        cs.cs_net_profit,
        ss.ss_net_profit,
        ws.ws_net_profit
    FROM tpcds.date_dim d
    JOIN tpcds.store s
      ON s.s_closed_date_sk = d.d_date_sk
    JOIN tpcds.store_sales ss
      ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.catalog_sales cs
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_page wp
      ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_returns wr
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE s.s_state = 'CA'
      AND cd.cd_gender = 'M'
      AND d.d_year BETWEEN 1999 AND 2001
      AND cc.cc_market_manager LIKE '%John%'
      AND wp.wp_char_count > 3000
),
per_store_year AS (
    SELECT
        s_store_name,
        d_year,
        SUM(cs_net_profit) AS catalog_profit,
        SUM(ss_net_profit) AS store_profit,
        SUM(ws_net_profit) AS web_profit,
        SUM(cs_net_profit + ss_net_profit + ws_net_profit) AS total_profit
    FROM base
    GROUP BY s_store_name, d_year
)
SELECT
    u.s_store_name,
    u.d_year,
    u.total_profit,
    ROW_NUMBER() OVER (PARTITION BY u.d_year ORDER BY u.total_profit DESC) AS rn
FROM (
    SELECT s_store_name, d_year, total_profit
    FROM per_store_year
    WHERE d_year = 1999
    UNION
    SELECT s_store_name, d_year, total_profit
    FROM per_store_year
    WHERE d_year = 2000
) AS u
WHERE u.total_profit > (SELECT AVG(total_profit) FROM per_store_year)
ORDER BY u.d_year, u.total_profit DESC
LIMIT 100
