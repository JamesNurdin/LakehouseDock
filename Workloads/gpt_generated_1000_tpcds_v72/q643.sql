WITH sales_agg AS (
    SELECT
        i.i_brand               AS brand,
        i.i_brand_id            AS brand_id,
        i.i_item_id             AS item_id,
        i.i_product_name        AS product_name,
        SUM(ws.ws_ext_sales_price)   AS total_sales,
        SUM(ws.ws_net_profit)        AS total_profit,
        AVG(ws.ws_ext_discount_amt)  AS avg_discount,
        CASE
            WHEN SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) > 0.2 THEN 'High'
            ELSE 'Low'
        END                         AS profit_category
    FROM web_sales ws
    LEFT JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE
        ws.ws_quantity >= 2
        AND ws.ws_list_price >= 100
        AND i.i_rec_start_date >= DATE '2000-01-01'
        AND i.i_formulation LIKE '%blue%'
    GROUP BY i.i_brand, i.i_brand_id, i.i_item_id, i.i_product_name
    HAVING SUM(ws.ws_ext_sales_price) > 5000
)
SELECT
    brand,
    brand_id,
    item_id,
    product_name,
    total_sales,
    total_profit,
    avg_discount,
    profit_category,
    RANK() OVER (PARTITION BY brand ORDER BY total_sales DESC) AS brand_sales_rank
FROM sales_agg
ORDER BY total_sales DESC, brand_sales_rank
LIMIT 100
