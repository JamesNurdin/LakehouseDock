/* goal: Summarize net profit and sales performance per item brand across web sites, applying several business filters, then compute average profit per brand and related statistics. */
WITH site_item_agg AS (
    SELECT
        ws.ws_web_site_sk,
        i.i_brand,
        SUM(ws.ws_net_profit) AS brand_site_net_profit,
        AVG(ws.ws_sales_price) AS brand_site_avg_sales_price,
        COUNT(*) AS txn_count,
        CASE WHEN i.i_size = 'extra large' THEN 'XL' ELSE 'Other' END AS size_category
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE s.web_rec_start_date <= DATE '2000-01-01'
      AND s.web_rec_end_date   >= DATE '2000-12-31'
      AND i.i_manager_id IN (6, 21, 98)
      AND i.i_wholesale_cost > 5
      AND ws.ws_sales_price < 100
    GROUP BY ws.ws_web_site_sk,
             i.i_brand,
             CASE WHEN i.i_size = 'extra large' THEN 'XL' ELSE 'Other' END
)
SELECT
    agg.i_brand,
    AVG(agg.brand_site_net_profit) AS avg_net_profit_per_brand,
    SUM(agg.txn_count) AS total_transactions,
    CASE WHEN AVG(agg.brand_site_avg_sales_price) > 50 THEN 'High' ELSE 'Low' END AS price_level,
    (SELECT COUNT(DISTINCT ws3.ws_item_sk)
       FROM web_sales ws3
       JOIN item i3 ON ws3.ws_item_sk = i3.i_item_sk
       WHERE i3.i_brand = agg.i_brand) AS distinct_items_for_brand
FROM site_item_agg agg
GROUP BY agg.i_brand
HAVING AVG(agg.brand_site_net_profit) > 500
ORDER BY avg_net_profit_per_brand DESC
LIMIT 100
