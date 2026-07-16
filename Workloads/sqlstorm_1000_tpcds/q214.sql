WITH sales_union AS (
  SELECT cs.cs_sold_date_sk AS sold_date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_quantity AS quantity,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit,
         cs.cs_ext_discount_amt AS discount_amt,
         cs.cs_promo_sk AS promo_sk,
         'catalog' AS sales_channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_quantity,
         ss.ss_net_paid,
         ss.ss_net_profit,
         ss.ss_ext_discount_amt,
         ss.ss_promo_sk,
         'store' AS sales_channel
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_item_sk,
         ws.ws_quantity,
         ws.ws_net_paid,
         ws.ws_net_profit,
         ws.ws_ext_discount_amt,
         ws.ws_promo_sk,
         'web' AS sales_channel
  FROM web_sales ws
),
returns_union AS (
  SELECT cr.cr_returned_date_sk AS return_date_sk,
         cr.cr_item_sk AS item_sk,
         cr.cr_return_quantity AS quantity,
         cr.cr_return_amt_inc_tax AS return_amount,
         cr.cr_refunded_cash AS refunded_cash,
         'catalog' AS return_channel
  FROM catalog_returns cr
  UNION ALL
  SELECT sr.sr_returned_date_sk,
         sr.sr_item_sk,
         sr.sr_return_quantity,
         sr.sr_return_amt_inc_tax,
         sr.sr_refunded_cash,
         'store' AS return_channel
  FROM store_returns sr
  UNION ALL
  SELECT wr.wr_returned_date_sk,
         wr.wr_item_sk,
         wr.wr_return_quantity,
         wr.wr_return_amt_inc_tax,
         wr.wr_refunded_cash,
         'web' AS return_channel
  FROM web_returns wr
),
item_details AS (
  SELECT i.i_item_sk,
         i.i_item_id,
         i.i_product_name,
         i.i_category,
         i.i_class,
         i.i_brand,
         i.i_current_price,
         i.i_color
  FROM item i
),
promo_details AS (
  SELECT p.p_promo_sk,
         p.p_promo_name,
         p.p_discount_active,
         p.p_start_date_sk,
         p.p_end_date_sk
  FROM promotion p
),
sales_agg AS (
  SELECT su.item_sk,
         d.d_year AS d_year,
         SUM(su.quantity) AS total_quantity,
         SUM(su.net_paid) AS total_net_paid,
         SUM(su.net_profit) AS total_net_profit,
         AVG(su.discount_amt) AS avg_discount,
         COUNT(DISTINCT su.promo_sk) AS distinct_promos,
         SUM(CASE WHEN su.sales_channel = 'web' THEN 1 ELSE 0 END) AS web_sales_cnt,
         SUM(CASE WHEN su.sales_channel = 'store' THEN 1 ELSE 0 END) AS store_sales_cnt,
         SUM(CASE WHEN su.sales_channel = 'catalog' THEN 1 ELSE 0 END) AS catalog_sales_cnt
  FROM sales_union su
  JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
  GROUP BY su.item_sk, d.d_year
),
returns_agg AS (
  SELECT ru.item_sk,
         d.d_year AS d_year,
         SUM(ru.quantity) AS total_return_quantity,
         SUM(ru.return_amount) AS total_return_amount,
         SUM(ru.refunded_cash) AS total_refunded_cash,
         COUNT(*) AS return_transactions
  FROM returns_union ru
  JOIN date_dim d ON ru.return_date_sk = d.d_date_sk
  GROUP BY ru.item_sk, d.d_year
),
final AS (
  SELECT i.i_category,
         i.i_class,
         i.i_brand,
         s.d_year,
         s.total_quantity,
         s.total_net_paid,
         s.total_net_profit,
         s.avg_discount,
         r.total_return_quantity,
         r.total_return_amount,
         r.total_refunded_cash,
         s.total_net_paid - COALESCE(r.total_return_amount, 0) AS net_sales_after_returns,
         (s.total_net_profit - COALESCE(r.total_return_amount, 0)) / NULLIF(s.total_net_paid, 0) AS profit_margin_after_returns,
         ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY s.total_net_profit DESC) AS profit_rank_year
  FROM sales_agg s
  LEFT JOIN returns_agg r ON s.item_sk = r.item_sk AND s.d_year = r.d_year
  JOIN item_details i ON s.item_sk = i.i_item_sk
)
SELECT d_year,
       i_category,
       i_class,
       i_brand,
       total_quantity,
       total_net_paid,
       total_net_profit,
       avg_discount,
       total_return_quantity,
       total_return_amount,
       total_refunded_cash,
       net_sales_after_returns,
       profit_margin_after_returns,
       profit_rank_year
FROM final
WHERE profit_rank_year <= 10
ORDER BY d_year, profit_rank_year
