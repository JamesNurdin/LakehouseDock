SELECT
    t.d_year,
    t.i_category,
    t.cd_gender,
    sum(t.net_paid) AS total_net_paid,
    sum(t.net_profit) AS total_net_profit
FROM (
    SELECT
        d.d_year,
        i.i_category,
        cd.cd_gender,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2000

    UNION ALL

    SELECT
        d.d_year,
        i.i_category,
        cd.cd_gender,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2000

    UNION ALL

    SELECT
        d.d_year,
        i.i_category,
        cd.cd_gender,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2000
) AS t
GROUP BY t.d_year, t.i_category, t.cd_gender
ORDER BY total_net_paid DESC
LIMIT 10
