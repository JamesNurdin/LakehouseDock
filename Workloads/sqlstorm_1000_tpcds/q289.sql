WITH unified_sales AS (
   SELECT ss_sold_date_sk AS date_sk,
          ss_item_sk AS item_sk,
          ss_net_profit AS net_profit,
          ss_net_paid AS net_paid,
          ss_quantity AS quantity,
          ss_ext_discount_amt AS discount,
          CASE WHEN ss_promo_sk IS NOT NULL THEN 1 ELSE 0 END AS promo_flag
   FROM store_sales
   UNION ALL
   SELECT cs_sold_date_sk,
          cs_item_sk,
          cs_net_profit,
          cs_net_paid,
          cs_quantity,
          cs_ext_discount_amt,
          CASE WHEN cs_promo_sk IS NOT NULL THEN 1 ELSE 0 END
   FROM catalog_sales
   UNION ALL
   SELECT ws_sold_date_sk,
          ws_item_sk,
          ws_net_profit,
          ws_net_paid,
          ws_quantity,
          ws_ext_discount_amt,
          CASE WHEN ws_promo_sk IS NOT NULL THEN 1 ELSE 0 END
   FROM web_sales
), sales_by_month_item AS (
   SELECT d.d_year,
          d.d_month_seq,
          i.i_item_sk,
          i.i_product_name,
          i.i_brand,
          i.i_category,
          SUM(s.net_profit) AS total_profit,
          SUM(s.net_paid) AS total_paid,
          SUM(s.quantity) AS total_qty,
          AVG(s.promo_flag) AS promo_rate,
          SUM(s.discount) AS total_discount
   FROM unified_sales s
   JOIN date_dim d ON s.date_sk = d.d_date_sk
   JOIN item i ON s.item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_year, d.d_month_seq, i.i_item_sk, i.i_product_name, i.i_brand, i.i_category
), ranked_sales AS (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_profit DESC) AS rn,
          SUM(total_profit) OVER (PARTITION BY d_year, d_month_seq) AS month_profit,
          SUM(total_profit) OVER (
               PARTITION BY d_year, d_month_seq
               ORDER BY total_profit DESC
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
          ) AS cumulative_profit
   FROM sales_by_month_item
)
SELECT d_year,
       d_month_seq,
       i_item_sk,
       i_product_name,
       i_brand,
       i_category,
       total_profit,
       total_paid,
       total_qty,
       promo_rate,
       total_discount,
       total_profit / month_profit AS profit_share,
       cumulative_profit / month_profit AS cumulative_share
FROM ranked_sales
WHERE rn <= 5
ORDER BY d_year, d_month_seq, rn
