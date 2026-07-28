/*
  Goal: Determine which web sites are experiencing the highest net loss relative to their total sales, focusing on high‑value orders with substantial shipping costs and specific market descriptions.
*/
WITH site_returns AS (
    SELECT
        ws.ws_web_site_sk,
        site.web_name,
        site.web_mkt_desc,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        -- correlated scalar subquery to fetch the total sales amount for the site
        (SELECT SUM(ws2.ws_ext_sales_price)
         FROM web_sales ws2
         WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk) AS site_sales_total
    FROM web_sales ws
    JOIN web_site site
      ON ws.ws_web_site_sk = site.web_site_sk
    JOIN web_returns wr
      ON wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
    WHERE ws.ws_ext_ship_cost > 200
      AND ws.ws_wholesale_cost < 80
      AND ws.ws_net_paid_inc_tax > 500
      AND wr.wr_return_tax BETWEEN 5 AND 150
      AND wr.wr_return_amt > 20
      AND site.web_suite_number = 'Suite 130'
      AND site.web_mkt_desc LIKE '%Company%'
    GROUP BY ws.ws_web_site_sk, site.web_name, site.web_mkt_desc, site.web_suite_number
),
final AS (
    SELECT
        *,
        total_net_loss / NULLIF(site_sales_total, 0) AS loss_ratio,
        AVG(total_net_loss / NULLIF(site_sales_total, 0)) OVER () AS avg_loss_ratio_all
    FROM site_returns
)
SELECT
    web_name,
    web_mkt_desc,
    total_net_loss,
    total_net_profit,
    order_cnt,
    site_sales_total,
    loss_ratio,
    avg_loss_ratio_all,
    CASE WHEN total_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
FROM final
WHERE total_net_loss > 1000
  AND total_net_profit < 5000
  AND order_cnt >= 10
  AND loss_ratio < 0.05
ORDER BY loss_ratio ASC
LIMIT 20
