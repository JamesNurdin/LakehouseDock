SELECT *
FROM (
    SELECT d_year,
           state,
           i_category,
           total_profit,
           total_paid,
           ROW_NUMBER() OVER (PARTITION BY d_year, state ORDER BY total_profit DESC) AS rn
    FROM (
        SELECT d.d_year,
               COALESCE(s.s_state, cc.cc_state, 'UNKNOWN') AS state,
               i.i_category,
               SUM(sales.net_profit) AS total_profit,
               SUM(sales.net_paid) AS total_paid
        FROM (
            SELECT cs.cs_sold_date_sk AS date_sk,
                   cs.cs_call_center_sk AS call_center_sk,
                   NULL AS store_sk,
                   cs.cs_item_sk AS item_sk,
                   cs.cs_net_profit AS net_profit,
                   cs.cs_net_paid AS net_paid
            FROM catalog_sales cs
            UNION ALL
            SELECT ss.ss_sold_date_sk AS date_sk,
                   NULL AS call_center_sk,
                   ss.ss_store_sk AS store_sk,
                   ss.ss_item_sk AS item_sk,
                   ss.ss_net_profit AS net_profit,
                   ss.ss_net_paid AS net_paid
            FROM store_sales ss
            UNION ALL
            SELECT ws.ws_sold_date_sk AS date_sk,
                   NULL AS call_center_sk,
                   NULL AS store_sk,
                   ws.ws_item_sk AS item_sk,
                   ws.ws_net_profit AS net_profit,
                   ws.ws_net_paid AS net_paid
            FROM web_sales ws
        ) sales
        LEFT JOIN date_dim d ON d.d_date_sk = sales.date_sk
        LEFT JOIN store s ON s.s_store_sk = sales.store_sk
        LEFT JOIN call_center cc ON cc.cc_call_center_sk = sales.call_center_sk
        LEFT JOIN item i ON i.i_item_sk = sales.item_sk
        WHERE d.d_year BETWEEN 2000 AND 2002
        GROUP BY d.d_year,
                 COALESCE(s.s_state, cc.cc_state, 'UNKNOWN'),
                 i.i_category
    ) agg
) t
WHERE rn <= 10
ORDER BY d_year, state, total_profit DESC
