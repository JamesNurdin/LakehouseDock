WITH site_sales AS (
    SELECT
        ws_site.web_site_sk,
        ws_site.web_site_id,
        ws_site.web_name,
        COALESCE(ws.ws_net_profit, 0) AS net_profit,
        COALESCE(wr.wr_return_amt_inc_tax, 0) AS return_amount,
        CASE
            WHEN COALESCE(ws.ws_net_profit, 0) > 1000 THEN 'High'
            WHEN COALESCE(ws.ws_net_profit, 0) > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM web_site ws_site
    LEFT OUTER JOIN web_sales ws
        ON ws.ws_web_site_sk = ws_site.web_site_sk
        AND ws.ws_ext_list_price > 2000
        AND ws.ws_sales_price BETWEEN 20 AND 100
        AND ws.ws_quantity >= 2
        AND ws.ws_ext_wholesale_cost < 5000
    LEFT OUTER JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_return_amt_inc_tax > 0
    WHERE ws_site.web_class = 'Unknown'
      AND ws_site.web_suite_number LIKE 'Suite %'
),
site_agg AS (
    SELECT
        web_site_sk,
        web_site_id,
        web_name,
        profit_category,
        SUM(net_profit) AS total_net_profit,
        SUM(return_amount) AS total_return_amount
    FROM site_sales
    GROUP BY web_site_sk, web_site_id, web_name, profit_category
)
SELECT
    web_site_sk,
    web_site_id,
    web_name,
    profit_category,
    total_net_profit,
    total_return_amount,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS site_rank
FROM site_agg
ORDER BY site_rank
LIMIT 100
