WITH sales AS (
    SELECT 
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_store_sk AS entity_sk,
        ss.ss_ticket_number AS order_number,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_sales,
        ss.ss_net_profit AS net_profit,
        i.i_category AS category,
        i.i_product_name AS product_name,
        'store' AS channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk

    UNION ALL

    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_order_number,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        i.i_category,
        i.i_product_name,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk

    UNION ALL

    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_web_page_sk,
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        i.i_category,
        i.i_product_name,
        'web' AS channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
), aggregated AS (
    SELECT
        d.d_year AS d_year,
        s.channel,
        s.category,
        sum(s.net_sales) AS total_sales,
        sum(s.net_profit) AS total_profit,
        sum(s.quantity) AS total_quantity,
        count(DISTINCT s.order_number) AS order_cnt,
        count(DISTINCT s.customer_sk) AS customer_cnt,
        approx_percentile(s.net_sales, 0.5) AS median_sales
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY d.d_year, s.channel, s.category
), ranked AS (
    SELECT
        *,
        row_number() OVER (PARTITION BY d_year, channel ORDER BY total_sales DESC) AS category_rank
    FROM aggregated
)
SELECT
    d_year,
    channel,
    category,
    total_sales,
    total_profit,
    total_quantity,
    order_cnt,
    customer_cnt,
    median_sales,
    category_rank
FROM ranked
WHERE category_rank <= 3
ORDER BY d_year, channel, category_rank
