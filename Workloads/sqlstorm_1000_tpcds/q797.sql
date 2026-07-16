SELECT
    state,
    category,
    gender,
    SUM(net_paid) AS total_sales,
    SUM(net_profit) AS total_profit
FROM (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        s.s_state AS state,
        i.i_category AS category,
        cd.cd_gender AS gender,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001

    UNION ALL

    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cc.cc_state AS state,
        i.i_category AS category,
        cd.cd_gender AS gender,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001

    UNION ALL

    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        wsite.web_state AS state,
        i.i_category AS category,
        cd.cd_gender AS gender,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
) AS all_sales
GROUP BY
    state,
    category,
    gender
ORDER BY
    total_sales DESC
LIMIT 100
