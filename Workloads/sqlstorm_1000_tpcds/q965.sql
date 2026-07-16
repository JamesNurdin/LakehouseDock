WITH store_data AS (
   SELECT d.d_year AS year,
          'Store' AS channel,
          i.i_category AS category,
          ss.ss_quantity AS quantity,
          ss.ss_net_profit AS net_profit,
          ss.ss_net_paid AS revenue,
          ss.ss_ext_discount_amt AS discount,
          ss.ss_ext_sales_price AS ext_sales_price
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1998 AND 2002
), catalog_data AS (
   SELECT d.d_year AS year,
          'Catalog' AS channel,
          i.i_category AS category,
          cs.cs_quantity AS quantity,
          cs.cs_net_profit AS net_profit,
          cs.cs_net_paid AS revenue,
          cs.cs_ext_discount_amt AS discount,
          cs.cs_ext_sales_price AS ext_sales_price
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1998 AND 2002
), web_data AS (
   SELECT d.d_year AS year,
          'Web' AS channel,
          i.i_category AS category,
          ws.ws_quantity AS quantity,
          ws.ws_net_profit AS net_profit,
          ws.ws_net_paid AS revenue,
          ws.ws_ext_discount_amt AS discount,
          ws.ws_ext_sales_price AS ext_sales_price
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1998 AND 2002
), combined AS (
   SELECT * FROM store_data
   UNION ALL
   SELECT * FROM catalog_data
   UNION ALL
   SELECT * FROM web_data
), aggregated AS (
   SELECT
      year,
      channel,
      category,
      SUM(quantity) AS total_quantity,
      SUM(revenue) AS total_revenue,
      SUM(net_profit) AS total_profit,
      AVG(discount) AS avg_discount,
      RANK() OVER (PARTITION BY year, channel ORDER BY SUM(net_profit) DESC) AS profit_rank
   FROM combined
   GROUP BY year, channel, category
   HAVING SUM(net_profit) > 0
)
SELECT
   year,
   channel,
   category,
   total_quantity,
   total_revenue,
   total_profit,
   avg_discount,
   profit_rank,
   SUM(total_profit) OVER (PARTITION BY channel, category ORDER BY year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3yr_profit
FROM aggregated
ORDER BY year, channel, profit_rank
LIMIT 200
