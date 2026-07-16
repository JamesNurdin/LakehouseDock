SELECT d.d_year,
       ca.ca_state,
       SUM(s.net_profit) AS total_profit,
       SUM(s.sales_quantity) AS total_quantity,
       COUNT(*) AS sale_count
FROM (
    SELECT ss_sold_date_sk AS sold_date_sk,
           ss_addr_sk AS addr_sk,
           ss_net_profit AS net_profit,
           ss_quantity AS sales_quantity
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_bill_addr_sk,
           ws_net_profit,
           ws_quantity
    FROM web_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_bill_addr_sk,
           cs_net_profit,
           cs_quantity
    FROM catalog_sales
) s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
JOIN customer_address ca ON s.addr_sk = ca.ca_address_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, ca.ca_state
ORDER BY d.d_year, ca.ca_state
