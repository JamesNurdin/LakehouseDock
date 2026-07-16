WITH sales AS (
    SELECT 'store' AS channel,
           d.d_year AS year,
           d.d_moy AS month,
           ss.ss_item_sk AS item_sk,
           ss.ss_ticket_number AS order_number,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_ext_discount_amt AS discount_amt,
           ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT 'catalog' AS channel,
           d.d_year AS year,
           d.d_moy AS month,
           cs.cs_item_sk AS item_sk,
           cs.cs_order_number AS order_number,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           cs.cs_ext_discount_amt AS discount_amt,
           cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT 'web' AS channel,
           d.d_year AS year,
           d.d_moy AS month,
           ws.ws_item_sk AS item_sk,
           ws.ws_order_number AS order_number,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           ws.ws_ext_discount_amt AS discount_amt,
           ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
returns AS (
    SELECT 'store' AS channel,
           d.d_year AS year,
           d.d_moy AS month,
           sr.sr_ticket_number AS order_number,
           sr.sr_net_loss AS net_loss,
           sr.sr_return_quantity AS return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT 'catalog' AS channel,
           d.d_year AS year,
           d.d_moy AS month,
           cr.cr_order_number AS order_number,
           cr.cr_net_loss AS net_loss,
           cr.cr_return_quantity AS return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    UNION ALL
    SELECT 'web' AS channel,
           d.d_year AS year,
           d.d_moy AS month,
           wr.wr_order_number AS order_number,
           wr.wr_net_loss AS net_loss,
           wr.wr_return_quantity AS return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
),
sales_agg AS (
    SELECT s.channel,
           s.year,
           s.month,
           i.i_item_id AS i_item_id,
           i.i_product_name AS i_product_name,
           SUM(s.net_paid) AS total_net_paid,
           SUM(s.net_profit) AS total_net_profit,
           AVG(s.discount_amt) AS avg_discount_amt,
           COUNT(DISTINCT s.order_number) AS distinct_orders,
           COUNT(*) AS total_sales_qty,
           COUNT(DISTINCT s.promo_sk) AS promo_count
    FROM sales s
    JOIN item i ON s.item_sk = i.i_item_sk
    WHERE s.year = 2001
    GROUP BY s.channel, s.year, s.month, i.i_item_id, i.i_product_name
),
returns_agg AS (
    SELECT r.channel,
           r.year,
           r.month,
           SUM(r.net_loss) AS total_return_loss,
           COUNT(DISTINCT r.order_number) AS distinct_return_orders,
           SUM(r.return_qty) AS total_return_qty
    FROM returns r
    WHERE r.year = 2001
    GROUP BY r.channel, r.year, r.month
)
SELECT sa.channel,
       sa.year,
       sa.month,
       sa.i_item_id,
       sa.i_product_name,
       sa.total_net_paid,
       sa.total_net_profit,
       COALESCE(ra.total_return_loss, 0) AS total_return_loss,
       (sa.total_net_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_adj,
       sa.avg_discount_amt,
       sa.promo_count,
       sa.distinct_orders,
       sa.total_sales_qty,
       COALESCE(ra.distinct_return_orders, 0) AS distinct_return_orders,
       COALESCE(ra.total_return_qty, 0) AS total_return_qty,
       RANK() OVER (PARTITION BY sa.channel ORDER BY (sa.total_net_profit - COALESCE(ra.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg sa
LEFT JOIN returns_agg ra
  ON sa.channel = ra.channel AND sa.year = ra.year AND sa.month = ra.month
ORDER BY sa.channel, profit_rank
LIMIT 100
