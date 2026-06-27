WITH cat_sales AS (
    SELECT
        i.i_category,
        date_trunc('month', d.d_date) AS month,
        SUM(cs.cs_net_profit) AS cat_net_profit,
        SUM(cs.cs_ext_sales_price) AS cat_sales_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
    GROUP BY i.i_category, date_trunc('month', d.d_date)
),
web_sales AS (
    SELECT
        i.i_category,
        date_trunc('month', d.d_date) AS month,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
    GROUP BY i.i_category, date_trunc('month', d.d_date)
)
SELECT
    cat.i_category,
    cat.month,
    cat.cat_net_profit,
    web.web_net_profit,
    cat.cat_net_profit + web.web_net_profit AS total_net_profit,
    CASE WHEN cat.cat_net_profit = 0 THEN NULL
         ELSE web.web_net_profit / cat.cat_net_profit END AS web_to_cat_profit_ratio
FROM cat_sales cat
JOIN web_sales web
  ON cat.i_category = web.i_category
 AND cat.month = web.month
ORDER BY total_net_profit DESC
LIMIT 10
