WITH sales_by_brand_category AS (
    SELECT
        i.i_brand,
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
    FROM web_sales ws
    LEFT JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_net_paid_inc_ship > 1000
      AND ws.ws_ext_ship_cost BETWEEN 100 AND 2000
      AND ws.ws_quantity >= 1
      AND i.i_rec_end_date >= DATE '2000-01-01'
      AND i.i_formulation LIKE '%plum%'
      AND i.i_color IS NOT NULL
    GROUP BY i.i_brand, i.i_category
),
category_stats AS (
    SELECT
        i_category,
        AVG(total_sales) AS avg_category_sales
    FROM sales_by_brand_category
    GROUP BY i_category
)
SELECT
    sbc.i_brand,
    sbc.i_category,
    sbc.total_sales,
    sbc.avg_profit,
    sbc.orders_cnt,
    cs.avg_category_sales,
    sbc.total_sales / cs.avg_category_sales AS sales_vs_category_ratio,
    RANK() OVER (PARTITION BY sbc.i_category ORDER BY sbc.total_sales DESC) AS brand_rank_in_category
FROM sales_by_brand_category sbc
JOIN category_stats cs
    ON sbc.i_category = cs.i_category
WHERE sbc.total_sales > cs.avg_category_sales * 1.5
  AND sbc.avg_profit > 100
  AND sbc.orders_cnt >= 5
ORDER BY sbc.total_sales DESC
LIMIT 100
