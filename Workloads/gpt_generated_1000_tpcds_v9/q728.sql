WITH combined_sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS profit_amount
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk IN (1, 2, 3)
    UNION ALL
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS profit_amount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk IN (1, 2, 3)
)
SELECT
    i_item_id,
    i_product_name,
    i_brand,
    i_category,
    SUM(sales_amount) AS total_sales_amount,
    SUM(profit_amount) AS total_profit_amount
FROM combined_sales
GROUP BY i_item_id, i_product_name, i_brand, i_category
ORDER BY total_profit_amount DESC
LIMIT 100
