WITH combined_sales AS (
    SELECT
        'store' AS channel,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS profit,
        ss.ss_ticket_number AS order_number
    FROM store_sales ss
    UNION ALL
    SELECT
        'web' AS channel,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_order_number
    FROM web_sales ws
    UNION ALL
    SELECT
        'catalog' AS channel,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
),
catalog_return_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_item_sk
),
sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(cs.sales_amount) AS total_sales,
        SUM(cs.profit) AS total_profit,
        COUNT(DISTINCT cs.order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.sales_amount) DESC) AS sales_rank
    FROM combined_sales cs
    JOIN date_dim d ON d.d_date_sk = cs.date_sk
    JOIN item i ON i.i_item_sk = cs.item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND cs.quantity > 0
    GROUP BY d.d_year, i.i_category
),
top_category_sales AS (
    SELECT
        d_year,
        i_category,
        total_sales,
        total_profit,
        total_orders
    FROM sales_agg
    WHERE sales_rank = 1
),
customer_loyalty AS (
    SELECT
        c.c_customer_id,
        SUM(COALESCE(cs.cs_ext_sales_price,0) + COALESCE(ws.ws_ext_sales_price,0) + COALESCE(ss.ss_ext_sales_price,0)) AS lifetime_spend,
        COUNT(DISTINCT COALESCE(cs.cs_order_number, ws.ws_order_number, ss.ss_ticket_number)) AS order_cnt,
        MIN(d.d_date) AS first_purchase,
        MAX(d.d_date) AS last_purchase
    FROM customer c
    LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d ON d.d_date_sk = COALESCE(cs.cs_sold_date_sk, ws.ws_sold_date_sk, ss.ss_sold_date_sk)
    WHERE COALESCE(cs.cs_ext_sales_price,0) + COALESCE(ws.ws_ext_sales_price,0) + COALESCE(ss.ss_ext_sales_price,0) > 0
    GROUP BY c.c_customer_id
    HAVING SUM(COALESCE(cs.cs_ext_sales_price,0) + COALESCE(ws.ws_ext_sales_price,0) + COALESCE(ss.ss_ext_sales_price,0)) > 10000
),
category_product_rank AS (
    SELECT
        i.i_category,
        i.i_product_name,
        SUM(cs.cs_ext_sales_price) AS product_sales,
        RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS prod_rank
    FROM catalog_sales cs
    JOIN item i ON i.i_item_sk = cs.cs_item_sk
    GROUP BY i.i_category, i.i_product_name
),
sales_and_returns AS (
    SELECT
        COALESCE(cs.channel, CASE WHEN cr.date_sk IS NOT NULL THEN 'catalog' END) AS channel,
        COALESCE(cs.date_sk, cr.date_sk) AS date_sk,
        COALESCE(cs.item_sk, cr.item_sk) AS item_sk,
        COALESCE(cs.sales_amount, 0) AS sales_amount,
        COALESCE(cs.quantity, 0) AS quantity,
        COALESCE(cs.profit, 0) - COALESCE(cr.total_return_loss, 0) AS net_profit,
        COALESCE(cr.total_return_amount, 0) AS return_amount
    FROM combined_sales cs
    FULL OUTER JOIN catalog_return_agg cr
        ON cs.channel = 'catalog' AND cs.date_sk = cr.date_sk AND cs.item_sk = cr.item_sk
),
final_metrics AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(sar.sales_amount) AS total_gross_sales,
        SUM(sar.sales_amount - sar.return_amount) AS total_net_sales,
        SUM(sar.net_profit) AS total_net_profit,
        COUNT(DISTINCT sar.item_sk) AS distinct_items_sold,
        ROUND(SUM(sar.sales_amount - sar.return_amount) / NULLIF(COUNT(DISTINCT sar.item_sk),0), 2) AS avg_sales_per_item,
        CONCAT('Year-', CAST(d.d_year AS VARCHAR), '-', i.i_category) AS key_label,
        CASE WHEN SUM(sar.net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        (
            SELECT SUM(cs2.cs_ext_sales_price)
            FROM catalog_sales cs2
            JOIN item i2 ON i2.i_item_sk = cs2.cs_item_sk
            JOIN date_dim d2 ON d2.d_date_sk = cs2.cs_sold_date_sk
            WHERE i2.i_category = i.i_category
              AND d2.d_year = d.d_year - 1
        ) AS prev_year_category_sales
    FROM sales_and_returns sar
    JOIN date_dim d ON d.d_date_sk = sar.date_sk
    JOIN item i ON i.i_item_sk = sar.item_sk
    GROUP BY d.d_year, i.i_category
    HAVING SUM(sar.sales_amount) > 0
),
final_with_top AS (
    SELECT
        fm.*,
        CASE WHEN fm.i_category = tcs.i_category THEN 1 ELSE 0 END AS is_top_category
    FROM final_metrics fm
    LEFT JOIN top_category_sales tcs ON tcs.d_year = fm.d_year
)
SELECT *
FROM final_with_top
WHERE profit_flag = 'POS'
ORDER BY total_net_profit DESC
LIMIT 100
