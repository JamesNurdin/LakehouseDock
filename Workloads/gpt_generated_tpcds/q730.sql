WITH store_sales_agg AS (
    SELECT
        i.i_category AS category,
        i.i_item_id AS item_id,
        p.p_promo_name AS promo_name,
        td.t_shift AS shift,
        SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY i.i_category, i.i_item_id, p.p_promo_name, td.t_shift
),
catalog_sales_agg AS (
    SELECT
        i.i_category AS category,
        i.i_item_id AS item_id,
        p.p_promo_name AS promo_name,
        td.t_shift AS shift,
        SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    GROUP BY i.i_category, i.i_item_id, p.p_promo_name, td.t_shift
),
web_sales_agg AS (
    SELECT
        i.i_category AS category,
        i.i_item_id AS item_id,
        p.p_promo_name AS promo_name,
        td.t_shift AS shift,
        SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    GROUP BY i.i_category, i.i_item_id, p.p_promo_name, td.t_shift
),
all_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
)
SELECT
    category,
    item_id,
    promo_name,
    shift,
    SUM(net_profit) AS total_net_profit
FROM all_sales
GROUP BY category, item_id, promo_name, shift
ORDER BY total_net_profit DESC
LIMIT 10
