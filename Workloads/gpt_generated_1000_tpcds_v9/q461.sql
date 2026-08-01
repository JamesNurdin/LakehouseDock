WITH filtered_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_ship_cost,
        ws.ws_ext_list_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ship_hdemo_sk,
        i.i_category_id,
        i.i_brand,
        i.i_brand_id,
        i.i_units
    FROM tpcds.web_sales ws
    LEFT OUTER JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_ext_ship_cost > 1000
      AND ws.ws_ext_list_price >= 10000
      AND ws.ws_ship_hdemo_sk IN (25, 6964)
      AND i.i_category_id IN (2, 4, 8)
      AND i.i_units IN ('Bundle', 'Case')
      AND i.i_brand_id > 1000000
),
agg_by_brand_category AS (
    SELECT
        i_brand,
        i_category_id,
        COUNT(*) AS total_transactions,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit,
        MIN(ws_ext_ship_cost) AS min_ship_cost,
        MAX(ws_ext_ship_cost) AS max_ship_cost,
        SUM(ws_ext_ship_cost) AS brand_ship_cost_sum
    FROM filtered_sales
    GROUP BY i_brand, i_category_id
)
SELECT
    i_brand,
    i_category_id,
    total_transactions,
    total_quantity,
    total_sales,
    avg_profit,
    min_ship_cost,
    max_ship_cost,
    SUM(brand_ship_cost_sum) OVER (PARTITION BY i_brand ORDER BY i_category_id) AS cumulative_ship_cost_by_brand
FROM agg_by_brand_category
ORDER BY total_sales DESC
LIMIT 100
