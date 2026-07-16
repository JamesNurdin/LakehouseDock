WITH
catalog_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        date_format(d.d_date, '%Y-%m') AS month_str,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS qty,
        SUM(cs.cs_ext_sales_price) AS sales,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_product_name, i.i_brand, date_format(d.d_date, '%Y-%m')
),
store_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        date_format(d.d_date, '%Y-%m') AS month_str,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS qty,
        SUM(ss.ss_ext_sales_price) AS sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_product_name, i.i_brand, date_format(d.d_date, '%Y-%m')
),
web_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        date_format(d.d_date, '%Y-%m') AS month_str,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS qty,
        SUM(ws.ws_ext_sales_price) AS sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_product_name, i.i_brand, date_format(d.d_date, '%Y-%m')
),
combined AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_brand,
        month_str,
        SUM(net_profit) AS total_net_profit,
        SUM(qty) AS total_qty,
        SUM(sales) AS total_sales,
        SUM(orders) AS total_orders
    FROM (
        SELECT i_item_sk, i_product_name, i_brand, month_str, net_profit, qty, sales, orders FROM catalog_sales_agg
        UNION ALL
        SELECT i_item_sk, i_product_name, i_brand, month_str, net_profit, qty, sales, orders FROM store_sales_agg
        UNION ALL
        SELECT i_item_sk, i_product_name, i_brand, month_str, net_profit, qty, sales, orders FROM web_sales_agg
    ) u
    GROUP BY i_item_sk, i_product_name, i_brand, month_str
),
ranked AS (
    SELECT
        i_item_sk,
        i_product_name,
        i_brand,
        month_str,
        total_net_profit,
        total_qty,
        total_sales,
        total_orders,
        ROW_NUMBER() OVER (PARTITION BY month_str ORDER BY total_net_profit DESC) AS rn,
        SUM(total_net_profit) OVER (PARTITION BY month_str) AS month_total_profit,
        (total_net_profit / NULLIF(SUM(total_net_profit) OVER (PARTITION BY month_str), 0)) * 100.0 AS profit_pct
    FROM combined
),
promotions_agg AS (
    SELECT p_item_sk AS i_item_sk, MAX(p_cost) AS max_promo_cost
    FROM promotion
    GROUP BY p_item_sk
)
SELECT
    c.i_item_sk,
    c.i_product_name,
    c.i_brand,
    c.month_str AS month,
    c.total_net_profit,
    c.total_qty,
    c.total_sales,
    c.total_orders,
    ROUND(c.profit_pct, 2) AS profit_pct,
    CASE
        WHEN c.profit_pct >= 10 THEN 'High'
        WHEN c.profit_pct >= 5 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    CONCAT(c.i_brand, ' - ', c.i_product_name) AS full_product_desc,
    COALESCE(
        (SELECT MAX(cs.cs_ext_sales_price) FROM catalog_sales cs WHERE cs.cs_item_sk = c.i_item_sk),
        (SELECT MAX(ss.ss_ext_sales_price) FROM store_sales ss WHERE ss.ss_item_sk = c.i_item_sk),
        (SELECT MAX(ws.ws_ext_sales_price) FROM web_sales ws WHERE ws.ws_item_sk = c.i_item_sk)
    ) AS max_sale_price,
    (SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_item_sk = c.i_item_sk) AS catalog_return_cnt,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = c.i_item_sk) AS store_return_cnt,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_item_sk = c.i_item_sk) AS web_return_cnt,
    p.max_promo_cost,
    CASE WHEN p.max_promo_cost IS NOT NULL THEN 1 ELSE 0 END AS has_promotion
FROM ranked c
LEFT JOIN promotions_agg p ON c.i_item_sk = p.i_item_sk
WHERE c.rn <= 5
ORDER BY c.month_str, c.profit_pct DESC
