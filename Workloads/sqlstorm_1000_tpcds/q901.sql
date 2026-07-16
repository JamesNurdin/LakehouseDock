WITH cat_sales AS (
    SELECT
        d.d_year AS sales_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        'Catalog' AS channel,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
        MAX(cs.cs_net_profit) AS max_item_profit,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS sales_amount,
        (SELECT MAX(cs2.cs_net_profit) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = cs.cs_item_sk) AS max_item_profit_all,
        CONCAT(i.i_brand, ' - ', i.i_product_name) AS brand_product_desc
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, i.i_product_name, cs.cs_item_sk
),
store_sales_agg AS (
    SELECT
        d.d_year AS sales_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        'Store' AS channel,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders_cnt,
        MAX(ss.ss_net_profit) AS max_item_profit,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS sales_amount,
        (SELECT MAX(ss2.ss_net_profit) FROM store_sales ss2 WHERE ss2.ss_item_sk = ss.ss_item_sk) AS max_item_profit_all,
        CONCAT(i.i_brand, ' - ', i.i_product_name) AS brand_product_desc
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, i.i_product_name, ss.ss_item_sk
),
web_sales_agg AS (
    SELECT
        d.d_year AS sales_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        'Web' AS channel,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
        MAX(ws.ws_net_profit) AS max_item_profit,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS sales_amount,
        (SELECT MAX(ws2.ws_net_profit) FROM web_sales ws2 WHERE ws2.ws_item_sk = ws.ws_item_sk) AS max_item_profit_all,
        CONCAT(i.i_brand, ' - ', i.i_product_name) AS brand_product_desc
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand, i.i_product_name, ws.ws_item_sk
),
union_sales AS (
    SELECT * FROM cat_sales
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
category_month_agg AS (
    SELECT
        sales_year,
        month_seq,
        i_category,
        channel,
        SUM(net_profit) AS total_net_profit,
        SUM(total_quantity) AS total_quantity,
        AVG(avg_discount) AS avg_discount,
        SUM(orders_cnt) AS total_orders,
        MAX(max_item_profit) AS max_item_profit,
        SUM(sales_amount) AS total_sales_amount,
        MAX(max_item_profit_all) AS max_item_profit_all,
        MIN(brand_product_desc) AS example_brand_product_desc
    FROM union_sales
    GROUP BY sales_year, month_seq, i_category, channel
),
category_inventory AS (
    SELECT
        cm.sales_year,
        cm.month_seq,
        cm.i_category,
        cm.channel,
        cm.total_net_profit,
        cm.total_quantity,
        cm.avg_discount,
        cm.total_orders,
        cm.max_item_profit,
        cm.total_sales_amount,
        cm.max_item_profit_all,
        COALESCE(inv.inv_quantity_on_hand, 0) AS quantity_on_hand,
        cm.example_brand_product_desc
    FROM category_month_agg cm
    LEFT JOIN (
        SELECT i.i_category, SUM(inv.inv_quantity_on_hand) AS inv_quantity_on_hand
        FROM inventory inv
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        GROUP BY i.i_category
    ) inv ON cm.i_category = inv.i_category
)
SELECT
    sales_year,
    month_seq,
    i_category,
    channel,
    total_net_profit,
    total_quantity,
    avg_discount,
    total_orders,
    max_item_profit,
    total_sales_amount,
    max_item_profit_all,
    quantity_on_hand,
    example_brand_product_desc,
    RANK() OVER (PARTITION BY sales_year, month_seq ORDER BY total_net_profit DESC) AS profit_rank,
    CASE WHEN total_sales_amount = 0 THEN NULL ELSE total_net_profit / total_sales_amount END AS profit_margin,
    REPLACE(CONCAT(COALESCE(i_category, 'UNKNOWN'), ':', COALESCE(example_brand_product_desc, 'N/A')), ' ', '_') AS cat_product_key
FROM category_inventory
WHERE total_net_profit IS NOT NULL
ORDER BY sales_year, month_seq, profit_rank
LIMIT 100
