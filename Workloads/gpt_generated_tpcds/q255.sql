WITH sales_agg AS (
    SELECT ss_item_sk AS i_item_sk, SUM(ss_net_profit) AS net_profit
    FROM store_sales
    GROUP BY ss_item_sk
    UNION ALL
    SELECT cs_item_sk AS i_item_sk, SUM(cs_net_profit) AS net_profit
    FROM catalog_sales
    GROUP BY cs_item_sk
    UNION ALL
    SELECT ws_item_sk AS i_item_sk, SUM(ws_net_profit) AS net_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
sales_total AS (
    SELECT i_item_sk, SUM(net_profit) AS total_sales_net_profit
    FROM sales_agg
    GROUP BY i_item_sk
),
returns_agg AS (
    SELECT sr_item_sk AS i_item_sk, SUM(sr_net_loss) AS net_loss
    FROM store_returns
    GROUP BY sr_item_sk
    UNION ALL
    SELECT cr_item_sk AS i_item_sk, SUM(cr_net_loss) AS net_loss
    FROM catalog_returns
    GROUP BY cr_item_sk
    UNION ALL
    SELECT wr_item_sk AS i_item_sk, SUM(wr_net_loss) AS net_loss
    FROM web_returns
    GROUP BY wr_item_sk
),
returns_total AS (
    SELECT i_item_sk, SUM(net_loss) AS total_returns_net_loss
    FROM returns_agg
    GROUP BY i_item_sk
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    i.i_category,
    i.i_brand,
    COALESCE(s.total_sales_net_profit, 0) AS total_sales_net_profit,
    COALESCE(r.total_returns_net_loss, 0) AS total_returns_net_loss,
    COALESCE(s.total_sales_net_profit, 0) - COALESCE(r.total_returns_net_loss, 0) AS net_profit_after_returns
FROM item i
LEFT JOIN sales_total s ON s.i_item_sk = i.i_item_sk
LEFT JOIN returns_total r ON r.i_item_sk = i.i_item_sk
WHERE i.i_category = 'Electronics'
ORDER BY net_profit_after_returns DESC
LIMIT 10
