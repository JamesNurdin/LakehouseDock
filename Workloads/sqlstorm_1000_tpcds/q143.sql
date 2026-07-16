WITH
store_sales_agg AS (
    SELECT
        d.d_year AS d_year,
        s.s_store_name AS store_name,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 1999
    GROUP BY d.d_year, s.s_store_name, i.i_category
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS d_year,
        cc.cc_name AS store_name,
        i.i_category AS category,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 1999
    GROUP BY d.d_year, cc.cc_name, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_year AS d_year,
        ws.ws_promo_sk AS promo_id,
        i.i_category AS category,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 1999
    GROUP BY d.d_year, ws.ws_promo_sk, i.i_category
)
SELECT
    d_year,
    store_name,
    category,
    net_paid,
    net_profit,
    channel
FROM (
    SELECT d_year, store_name, category, net_paid, net_profit, 'store' AS channel
    FROM store_sales_agg
    UNION ALL
    SELECT d_year, store_name, category, net_paid, net_profit, 'catalog' AS channel
    FROM catalog_sales_agg
    UNION ALL
    SELECT d_year, CAST(promo_id AS VARCHAR) AS store_name, category, net_paid, net_profit, 'web' AS channel
    FROM web_sales_agg
) t
ORDER BY d_year, channel, net_paid DESC
