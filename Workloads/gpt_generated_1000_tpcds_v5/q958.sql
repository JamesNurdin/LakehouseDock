WITH avg_discount AS (
    SELECT AVG(cs.cs_ext_discount_amt) AS avg_cs_discount
    FROM catalog_sales cs
)
SELECT
    i.i_category,
    s.s_store_name,
    wsite.web_name,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(cs.cs_ext_sales_price) AS catalog_sales,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_ext_sales_price ELSE 0 END) AS profitable_catalog_sales,
    (SELECT avg_cs_discount FROM avg_discount) AS avg_catalog_discount,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Overall Profit' ELSE 'Overall Loss' END AS overall_profit_flag
FROM
    catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
WHERE
    i.i_category_id = 5
    AND i.i_rec_start_date >= DATE '1999-01-01'
    AND s.s_state = 'CA'
    AND c.c_birth_year BETWEEN 1970 AND 1980
GROUP BY
    i.i_category,
    s.s_store_name,
    wsite.web_name
ORDER BY
    catalog_sales DESC
LIMIT 100
