WITH cs_agg AS (
    SELECT cs_item_sk,
           SUM(cs_net_profit) AS catalog_profit,
           SUM(cs_quantity) AS catalog_qty
    FROM catalog_sales
    GROUP BY cs_item_sk
),
ws_agg AS (
    SELECT ws_item_sk,
           SUM(ws_net_profit) AS web_profit,
           SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_sk
),
wr_agg AS (
    SELECT wr_item_sk,
           SUM(wr_net_loss) AS return_loss,
           SUM(wr_return_quantity) AS return_qty
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT
    COALESCE(cs_agg.cs_item_sk, ws_agg.ws_item_sk) AS item_sk,
    cs_agg.catalog_profit,
    ws_agg.web_profit,
    wr_agg.return_loss,
    (cs_agg.catalog_profit + ws_agg.web_profit) AS total_sales_profit,
    (cs_agg.catalog_profit + ws_agg.web_profit - COALESCE(wr_agg.return_loss, 0)) AS net_profit,
    CASE
        WHEN (cs_agg.catalog_profit + ws_agg.web_profit) = 0 THEN NULL
        ELSE (cs_agg.catalog_profit + ws_agg.web_profit - COALESCE(wr_agg.return_loss, 0)) / (cs_agg.catalog_profit + ws_agg.web_profit)
    END AS profit_margin,
    CASE
        WHEN (cs_agg.catalog_profit + ws_agg.web_profit - COALESCE(wr_agg.return_loss, 0)) / NULLIF((cs_agg.catalog_profit + ws_agg.web_profit), 0) > 0.5 THEN 'Excellent'
        WHEN (cs_agg.catalog_profit + ws_agg.web_profit - COALESCE(wr_agg.return_loss, 0)) / NULLIF((cs_agg.catalog_profit + ws_agg.web_profit), 0) > 0.2 THEN 'Good'
        WHEN (cs_agg.catalog_profit + ws_agg.web_profit - COALESCE(wr_agg.return_loss, 0)) / NULLIF((cs_agg.catalog_profit + ws_agg.web_profit), 0) > 0.0 THEN 'Average'
        ELSE 'Poor'
    END AS margin_category,
    RANK() OVER (ORDER BY (cs_agg.catalog_profit + ws_agg.web_profit - COALESCE(wr_agg.return_loss, 0)) DESC) AS profit_rank
FROM cs_agg
FULL OUTER JOIN ws_agg ON cs_agg.cs_item_sk = ws_agg.ws_item_sk
LEFT JOIN wr_agg ON COALESCE(cs_agg.cs_item_sk, ws_agg.ws_item_sk) = wr_agg.wr_item_sk
WHERE (cs_agg.catalog_profit + ws_agg.web_profit) IS NOT NULL
ORDER BY profit_rank
LIMIT 10
