WITH sales_with_avg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        (
            SELECT AVG(cs2.cs_sales_price)
            FROM catalog_sales cs2
            WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
        ) AS avg_sales_price_by_date
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_net_profit > 0
)
SELECT
    cp.cp_catalog_page_id,
    d.d_date,
    t.t_hour,
    SUM(s.cs_quantity) AS total_quantity,
    SUM(s.cs_net_profit) AS total_profit,
    AVG(s.cs_sales_price) AS avg_sales_price,
    COUNT(DISTINCT s.cs_item_sk) AS distinct_items_sold,
    COALESCE(SUM(i.inv_quantity_on_hand), 0) AS total_inventory_on_hand
FROM sales_with_avg s
JOIN date_dim d
    ON s.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON s.cs_sold_time_sk = t.t_time_sk
JOIN catalog_page cp
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND d.d_month_seq = 1212
    AND d.d_day_name = 'Monday'
    AND t.t_hour BETWEEN 9 AND 17
    AND cp.cp_department = 'Electronics'
    AND s.cs_sales_price > s.avg_sales_price_by_date
GROUP BY
    cp.cp_catalog_page_id,
    d.d_date,
    t.t_hour
HAVING
    SUM(s.cs_net_profit) > 1000
    AND COALESCE(SUM(i.inv_quantity_on_hand), 0) >= 50
ORDER BY
    total_profit DESC,
    total_quantity DESC
LIMIT 100
