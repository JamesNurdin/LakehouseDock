WITH unified_sales AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_ext_sales_price AS sales_amt,
           cs_ext_discount_amt AS discount_amt,
           cs_net_profit AS profit
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_ext_sales_price,
           ss_ext_discount_amt,
           ss_net_profit
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_ext_sales_price,
           ws_ext_discount_amt,
           ws_net_profit
    FROM web_sales
)
SELECT d.d_year,
       i.i_category AS category,
       SUM(us.sales_amt) AS total_sales,
       SUM(us.profit) AS total_profit,
       AVG(us.discount_amt) AS avg_discount,
       COUNT(*) AS sales_cnt
FROM unified_sales us
JOIN date_dim d ON us.date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1998 AND 1999
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, total_sales DESC
LIMIT 100
