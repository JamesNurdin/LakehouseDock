WITH unified_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS profit,
        cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_order_number
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    SUM(sales_amount) AS total_sales,
    SUM(profit) AS total_profit,
    SUM(profit) / NULLIF(SUM(sales_amount), 0) AS profit_margin,
    COUNT(DISTINCT order_number) AS distinct_orders
FROM unified_sales
WHERE d_year BETWEEN 1999 AND 2001
GROUP BY d_year, d_month_seq, i_category
ORDER BY total_sales DESC
LIMIT 100
