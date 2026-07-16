WITH
date_filter AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2001
      AND d_holiday = 'N'
),
item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        i.i_brand,
        'catalog' AS sales_channel,
        cs.cs_sold_date_sk AS sale_date_sk,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_ext_discount_amt AS ext_discount_amt,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_filter df ON cs.cs_sold_date_sk = df.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
store_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        i.i_brand,
        'store' AS sales_channel,
        ss.ss_sold_date_sk AS sale_date_sk,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_ext_discount_amt AS ext_discount_amt,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_filter df ON ss.ss_sold_date_sk = df.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
web_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        i.i_brand,
        'web' AS sales_channel,
        ws.ws_sold_date_sk AS sale_date_sk,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS ext_sales_price,
        ws.ws_ext_discount_amt AS ext_discount_amt,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_filter df ON ws.ws_sold_date_sk = df.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
combined_sales AS (
    SELECT * FROM item_sales
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
sales_with_rank AS (
    SELECT
        cs.i_item_sk,
        cs.i_item_id,
        cs.i_product_name,
        cs.i_brand,
        cs.i_current_price,
        cs.sales_channel,
        cs.sale_date_sk,
        cs.quantity,
        cs.ext_sales_price,
        cs.ext_discount_amt,
        cs.net_profit,
        SUM(cs.ext_sales_price) OVER (PARTITION BY cs.i_item_sk) AS total_item_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.sales_channel ORDER BY cs.ext_sales_price DESC) AS channel_sales_rank,
        RANK() OVER (ORDER BY cs.ext_sales_price DESC) AS overall_sales_rank,
        CASE WHEN cs.ext_sales_price = 0 THEN NULL ELSE cs.ext_discount_amt / cs.ext_sales_price END AS discount_rate,
        CASE
            WHEN cs.net_profit > 0 THEN 'PROFITABLE'
            WHEN cs.net_profit = 0 THEN 'BREAKEVEN'
            ELSE 'LOSS'
        END AS profit_status,
        CONCAT(cs.i_product_name, ' - ', COALESCE(cs.i_brand, 'UNKNOWN')) AS product_label,
        CASE
            WHEN cs.sales_channel = 'catalog' AND cs.quantity > 10 THEN 'BULK'
            WHEN cs.sales_channel = 'store' AND cs.quantity > 5 THEN 'MEDIUM'
            WHEN cs.sales_channel = 'web' AND cs.quantity > 2 THEN 'SMALL'
            ELSE 'OTHER'
        END AS sale_size_category
    FROM combined_sales cs
)
SELECT
    swr.i_item_sk,
    swr.i_item_id,
    swr.product_label,
    swr.sales_channel,
    swr.quantity,
    ROUND(swr.ext_sales_price, 2) AS ext_sales,
    ROUND(swr.ext_discount_amt, 2) AS discount,
    ROUND(swr.net_profit, 2) AS net_profit,
    ROUND(swr.total_item_sales, 2) AS total_item_sales,
    swr.channel_sales_rank,
    swr.overall_sales_rank,
    ROUND(swr.discount_rate * 100, 2) AS discount_pct,
    swr.profit_status,
    swr.sale_size_category,
    (SELECT AVG(cs2.net_profit) FROM combined_sales cs2 WHERE cs2.i_item_sk = swr.i_item_sk) AS avg_net_profit_across_channels,
    COALESCE(inv_total.ci_total_stock, 0) AS total_stock
FROM sales_with_rank swr
LEFT JOIN (
    SELECT i.i_item_sk,
           SUM(inv.inv_quantity_on_hand) AS ci_total_stock
    FROM item i
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_sk
) inv_total ON swr.i_item_sk = inv_total.i_item_sk
WHERE swr.overall_sales_rank <= 100
ORDER BY swr.overall_sales_rank
