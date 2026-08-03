WITH ws_agg AS (
    SELECT
        ws_web_site_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_item_sk) AS distinct_items,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales
    WHERE ws_ship_mode_sk IN (1, 6, 9, 17)
      AND ws_ext_wholesale_cost > 2000
      AND ws_ext_ship_cost BETWEEN 20 AND 500
      AND ws_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY ws_web_site_sk
)
SELECT
    ws_agg.ws_web_site_sk,
    web_site.web_site_id,
    web_site.web_mkt_class,
    ws_agg.total_profit,
    ws_agg.distinct_items,
    ws_agg.total_quantity,
    (
        SELECT SUM(ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = ws_agg.ws_web_site_sk
    ) AS site_sales_price,
    RANK() OVER (PARTITION BY web_site.web_mkt_class ORDER BY ws_agg.total_profit DESC) AS profit_rank,
    CASE WHEN ws_agg.total_profit > 100000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category
FROM ws_agg
JOIN web_site
  ON ws_agg.ws_web_site_sk = web_site.web_site_sk
WHERE
    web_site.web_mkt_id IN (1, 2, 4, 5)
    AND web_site.web_country = 'United States'
    AND web_site.web_gmt_offset BETWEEN -5 AND 5
    AND web_site.web_tax_percentage < 0.08
    AND EXISTS (
        SELECT 1
        FROM web_sales ws3
        WHERE ws3.ws_web_site_sk = ws_agg.ws_web_site_sk
          AND ws3.ws_quantity > 10
    )
ORDER BY ws_agg.total_profit DESC, web_site.web_site_id
LIMIT 100
