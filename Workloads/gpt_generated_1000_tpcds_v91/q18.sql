WITH high_stock_items AS (
    SELECT DISTINCT inv_item_sk
    FROM inventory
    WHERE inv_quantity_on_hand >= 800
)
SELECT
    channel,
    year,
    month_seq,
    SUM(net_paid) AS total_net_paid,
    CASE WHEN SUM(net_paid) > 10000 THEN 'High' ELSE 'Medium' END AS revenue_category,
    COUNT(DISTINCT order_number) AS distinct_orders
FROM (
    SELECT
        'Catalog' AS channel,
        cs.cs_order_number AS order_number,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_item_sk IN (SELECT inv_item_sk FROM high_stock_items)
      AND d.d_year = 2001
    UNION ALL
    SELECT
        'Web' AS channel,
        ws.ws_order_number AS order_number,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        ws.ws_net_paid AS net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_item_sk IN (SELECT inv_item_sk FROM high_stock_items)
      AND d.d_year = 2001
) AS combined
GROUP BY channel, year, month_seq
HAVING SUM(net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
