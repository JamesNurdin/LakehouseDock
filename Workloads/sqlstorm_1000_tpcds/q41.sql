WITH all_sales AS (
  SELECT dd.d_year AS d_year,
         i.i_category AS i_category,
         ws.ws_quantity AS quantity,
         ws.ws_ext_sales_price AS revenue,
         ws.ws_net_profit AS profit,
         ws.ws_ext_discount_amt AS discount
  FROM web_sales ws
  JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  UNION ALL
  SELECT dd.d_year,
         i.i_category,
         cs.cs_quantity,
         cs.cs_ext_sales_price,
         cs.cs_net_profit,
         cs.cs_ext_discount_amt
  FROM catalog_sales cs
  JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  UNION ALL
  SELECT dd.d_year,
         i.i_category,
         ss.ss_quantity,
         ss.ss_ext_sales_price,
         ss.ss_net_profit,
         ss.ss_ext_discount_amt
  FROM store_sales ss
  JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
)
SELECT d_year,
       i_category,
       sum(quantity) AS total_quantity,
       sum(revenue) AS total_revenue,
       sum(profit) AS total_profit,
       sum(discount) AS total_discount,
       sum(revenue) / nullif(sum(quantity), 0) AS avg_price,
       sum(profit) / nullif(sum(revenue), 0) AS profit_margin
FROM all_sales
WHERE d_year BETWEEN 1999 AND 2002
GROUP BY d_year, i_category
ORDER BY d_year, total_revenue DESC
