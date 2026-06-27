WITH sales AS (
    SELECT
        ws.ws_web_site_sk AS web_site_sk,
        ds.d_year,
        ds.d_moy,
        SUM(ws.ws_net_profit) AS total_sales_profit
    FROM web_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    GROUP BY ws.ws_web_site_sk, ds.d_year, ds.d_moy
),
returns AS (
    SELECT
        ws.ws_web_site_sk AS web_site_sk,
        dr.d_year,
        dr.d_moy,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
    GROUP BY ws.ws_web_site_sk, dr.d_year, dr.d_moy
)
SELECT
    web_site.web_name,
    sales.d_year,
    sales.d_moy,
    sales.total_sales_profit,
    COALESCE(returns.total_return_loss, 0) AS total_return_loss,
    sales.total_sales_profit - COALESCE(returns.total_return_loss, 0) AS net_profit_after_returns
FROM sales
LEFT JOIN returns
    ON sales.web_site_sk = returns.web_site_sk
   AND sales.d_year = returns.d_year
   AND sales.d_moy = returns.d_moy
JOIN web_site ON sales.web_site_sk = web_site.web_site_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100
