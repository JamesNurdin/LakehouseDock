WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_wholesale_cost,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        CASE
            WHEN ws.ws_net_profit > 1500 THEN 'HIGH'
            WHEN ws.ws_net_profit BETWEEN 500 AND 1500 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM web_sales ws
    WHERE ws.ws_wholesale_cost > 50.00
      AND ws.ws_quantity >= 2
      AND ws.ws_net_paid_inc_tax > 500.00
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2451000
),
site_joined AS (
    SELECT
        s.ws_web_site_sk,
        s.ws_order_number,
        s.profit_category,
        s.ws_net_paid_inc_tax,
        s.ws_net_profit,
        s.ws_quantity,
        COALESCE(w.web_country, 'UNKNOWN') AS web_country,
        COALESCE(w.web_tax_percentage, 0) AS web_tax_percentage,
        w.web_market_manager
    FROM sales_agg s
    LEFT JOIN web_site w
        ON s.ws_web_site_sk = w.web_site_sk
    WHERE COALESCE(w.web_country, 'UNKNOWN') = 'United States'
      AND COALESCE(w.web_tax_percentage, 0) >= 0.05
      AND (w.web_market_manager = 'Gerald Craft' OR w.web_market_manager = 'James Bernard')
      AND s.ws_web_site_sk IN (
          SELECT ws_web_site_sk FROM web_sales WHERE ws_quantity = 2
          UNION
          SELECT ws_web_site_sk FROM web_sales WHERE ws_quantity = 3
      )
)
SELECT
    sj.web_market_manager,
    sj.web_tax_percentage,
    COUNT(DISTINCT sj.ws_order_number) AS num_orders,
    SUM(sj.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(sj.ws_net_profit) AS avg_net_profit,
    SUM(CASE WHEN sj.profit_category = 'HIGH' THEN sj.ws_net_profit ELSE 0 END) AS high_profit_total
FROM site_joined sj
GROUP BY sj.web_market_manager, sj.web_tax_percentage
HAVING SUM(sj.ws_net_paid_inc_tax) > (
    SELECT AVG(ws_net_paid_inc_tax) FROM site_joined
)
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
