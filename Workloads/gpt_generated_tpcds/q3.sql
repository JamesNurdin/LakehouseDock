WITH catalog_sales_agg AS (
    SELECT i.i_brand AS brand,
           SUM(cs.cs_quantity) AS total_quantity_sold,
           SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_brand
),
catalog_returns_agg AS (
    SELECT i.i_brand AS brand,
           SUM(cr.cr_return_quantity) AS total_quantity_returned,
           SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_brand
),
web_returns_agg AS (
    SELECT i.i_brand AS brand,
           SUM(wr.wr_return_quantity) AS total_web_quantity_returned,
           SUM(wr.wr_net_loss) AS total_web_net_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_brand
)
SELECT cs.brand,
       cs.total_quantity_sold,
       cs.total_net_profit,
       cr.total_quantity_returned,
       cr.total_net_loss,
       wr.total_web_quantity_returned,
       wr.total_web_net_loss,
       (COALESCE(cr.total_quantity_returned, 0) + COALESCE(wr.total_web_quantity_returned, 0)) / NULLIF(cs.total_quantity_sold, 0) AS return_rate
FROM catalog_sales_agg cs
LEFT JOIN catalog_returns_agg cr ON cs.brand = cr.brand
LEFT JOIN web_returns_agg wr ON cs.brand = wr.brand
ORDER BY cs.total_net_profit DESC
LIMIT 100
