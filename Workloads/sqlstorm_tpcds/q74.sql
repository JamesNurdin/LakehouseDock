WITH sales_agg AS (
    SELECT s.s_store_sk,
           d.d_year,
           EXTRACT(month FROM d.d_date) AS sale_month,
           SUM(ss.ss_net_paid) AS total_net_paid,
           SUM(ss.ss_net_profit) AS total_net_profit,
           SUM(ss.ss_quantity) AS total_quantity,
           COUNT(DISTINCT ss.ss_ticket_number) AS order_count
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, d.d_year, EXTRACT(month FROM d.d_date)
),
returns_agg AS (
    SELECT s.s_store_sk,
           d.d_year,
           EXTRACT(month FROM d.d_date) AS sale_month,
           SUM(sr.sr_net_loss) AS total_net_loss,
           SUM(sr.sr_return_quantity) AS total_return_quantity,
           COUNT(DISTINCT sr.sr_ticket_number) AS return_order_count
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, d.d_year, EXTRACT(month FROM d.d_date)
),
item_ranking AS (
    SELECT s.s_store_sk,
           d.d_year,
           EXTRACT(month FROM d.d_date) AS sale_month,
           i.i_item_sk,
           i.i_product_name,
           SUM(ss.ss_net_profit) AS item_net_profit,
           ROW_NUMBER() OVER (
               PARTITION BY s.s_store_sk, d.d_year, EXTRACT(month FROM d.d_date)
               ORDER BY SUM(ss.ss_net_profit) DESC
           ) AS profit_rank
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY s.s_store_sk, d.d_year, EXTRACT(month FROM d.d_date), i.i_item_sk, i.i_product_name
)
SELECT s.s_store_id,
       s.s_store_name,
       sa.d_year,
       sa.sale_month,
       sa.total_net_paid,
       sa.total_net_profit,
       COALESCE(ra.total_net_loss, 0) AS total_net_loss,
       (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) AS net_profit_after_returns,
       sa.total_quantity,
       sa.order_count,
       COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
       COALESCE(ra.return_order_count, 0) AS return_order_count,
       ir.i_item_sk,
       ir.i_product_name,
       ir.item_net_profit,
       ir.profit_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
   AND sa.d_year = ra.d_year
   AND sa.sale_month = ra.sale_month
JOIN store s
    ON sa.s_store_sk = s.s_store_sk
LEFT JOIN item_ranking ir
    ON sa.s_store_sk = ir.s_store_sk
   AND sa.d_year = ir.d_year
   AND sa.sale_month = ir.sale_month
   AND ir.profit_rank <= 5
ORDER BY s.s_store_id, sa.d_year, sa.sale_month, ir.profit_rank
