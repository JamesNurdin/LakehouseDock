SELECT
    d_year,
    category,
    channel,
    SUM(sales_amount) AS total_sales,
    SUM(profit) AS total_profit,
    SUM(quantity) AS total_quantity
FROM (
    SELECT
        d.d_year AS d_year,
        i.i_category AS category,
        'catalog' AS channel,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS profit,
        cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        d.d_year,
        i.i_category,
        'store',
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk

    UNION ALL

    SELECT
        d.d_year,
        i.i_category,
        'web',
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
) t
GROUP BY d_year, category, channel
ORDER BY d_year, total_sales DESC
