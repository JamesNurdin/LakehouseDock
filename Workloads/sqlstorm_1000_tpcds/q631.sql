WITH fact AS (
   SELECT ss.ss_sold_date_sk AS sold_date_sk,
          ss.ss_item_sk AS item_sk,
          ss.ss_net_paid AS sales_amount,
          ss.ss_quantity AS sales_qty,
          ss.ss_net_profit AS sales_profit,
          ss.ss_sales_price AS sales_price,
          'store' AS channel
   FROM store_sales ss
   UNION ALL
   SELECT cs.cs_sold_date_sk,
          cs.cs_item_sk,
          cs.cs_net_paid,
          cs.cs_quantity,
          cs.cs_net_profit,
          cs.cs_sales_price,
          'catalog' AS channel
   FROM catalog_sales cs
   UNION ALL
   SELECT ws.ws_sold_date_sk,
          ws.ws_item_sk,
          ws.ws_net_paid,
          ws.ws_quantity,
          ws.ws_net_profit,
          ws.ws_sales_price,
          'web' AS channel
   FROM web_sales ws
),
joined AS (
   SELECT d.d_year,
          d.d_quarter_name,
          f.channel,
          i.i_category,
          i.i_brand,
          i.i_item_sk,
          i.i_product_name,
          f.sales_amount,
          f.sales_qty,
          f.sales_profit,
          f.sales_price,
          (
            SELECT coalesce(sum(p.p_cost), 0)
            FROM promotion p
            WHERE p.p_item_sk = f.item_sk
              AND f.sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
          ) AS promo_cost
   FROM fact f
   JOIN date_dim d ON f.sold_date_sk = d.d_date_sk
   JOIN item i ON f.item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 2001 AND 2003
),
agg AS (
   SELECT d_year,
          d_quarter_name,
          channel,
          i_category,
          i_brand,
          i_item_sk,
          i_product_name,
          sum(sales_amount) AS total_sales,
          sum(sales_qty) AS total_qty,
          sum(sales_profit) AS total_profit,
          avg(sales_price) AS avg_price,
          sum(promo_cost) AS total_promo_cost
   FROM joined
   GROUP BY d_year, d_quarter_name, channel, i_category, i_brand, i_item_sk, i_product_name
),
ranked AS (
   SELECT *,
          row_number() OVER (PARTITION BY d_year, d_quarter_name, channel, i_category ORDER BY total_sales DESC) AS rank_in_category
   FROM agg
)
SELECT d_year,
       d_quarter_name,
       channel,
       i_category,
       i_brand,
       i_item_sk,
       i_product_name,
       total_sales,
       total_qty,
       total_profit,
       avg_price,
       total_promo_cost,
       rank_in_category
FROM ranked
WHERE rank_in_category <= 5
ORDER BY d_year, d_quarter_name, channel, i_category, rank_in_category
