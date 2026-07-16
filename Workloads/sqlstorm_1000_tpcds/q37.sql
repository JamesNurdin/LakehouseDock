WITH combined_sales AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_quantity AS quantity,
         cs.cs_net_paid AS net_paid,
         cs.cs_net_profit AS net_profit,
         'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_quantity,
         ss.ss_net_paid,
         ss.ss_net_profit,
         'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_item_sk,
         ws.ws_quantity,
         ws.ws_net_paid,
         ws.ws_net_profit,
         'web' AS channel
  FROM web_sales ws
),
combined_returns AS (
  SELECT cr.cr_returned_date_sk AS date_sk,
         cr.cr_item_sk AS item_sk,
         cr.cr_return_quantity AS quantity,
         -cr.cr_return_amount AS net_paid,
         -cr.cr_net_loss AS net_profit,
         'catalog' AS channel
  FROM catalog_returns cr
  UNION ALL
  SELECT sr.sr_returned_date_sk,
         sr.sr_item_sk,
         sr.sr_return_quantity,
         -sr.sr_return_amt,
         -sr.sr_net_loss,
         'store' AS channel
  FROM store_returns sr
  UNION ALL
  SELECT wr.wr_returned_date_sk,
         wr.wr_item_sk,
         wr.wr_return_quantity,
         -wr.wr_return_amt,
         -wr.wr_net_loss,
         'web' AS channel
  FROM web_returns wr
),
aggregated AS (
  SELECT d.d_year,
         d.d_month_seq,
         p.p_promo_name,
         i.i_category,
         i.i_brand,
         s.channel,
         sum(s.quantity) AS total_quantity,
         sum(s.net_paid) AS total_net_paid,
         sum(s.net_profit) AS total_net_profit,
         sum(coalesce(r.quantity, 0)) AS total_return_quantity,
         sum(coalesce(r.net_paid, 0)) AS total_return_net_paid,
         sum(coalesce(r.net_profit, 0)) AS total_return_net_profit,
         sum(s.net_profit) + sum(coalesce(r.net_profit, 0)) AS net_margin,
         count(case when p.p_discount_active = 'Y' then 1 end) AS active_promo_cnt
  FROM combined_sales s
  LEFT JOIN combined_returns r
    ON s.date_sk = r.date_sk
   AND s.item_sk = r.item_sk
   AND s.channel = r.channel
  JOIN date_dim d
    ON s.date_sk = d.d_date_sk
  JOIN item i
    ON s.item_sk = i.i_item_sk
  LEFT JOIN promotion p
    ON i.i_item_sk = p.p_item_sk
  WHERE d.d_year = 2002
    AND d.d_moy BETWEEN 1 AND 12
  GROUP BY d.d_year,
           d.d_month_seq,
           p.p_promo_name,
           i.i_category,
           i.i_brand,
           s.channel
)
SELECT a.*,
       sum(a.net_margin) OVER (PARTITION BY a.d_year ORDER BY a.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_year_margin
FROM aggregated a
ORDER BY a.d_year,
         a.d_month_seq,
         a.net_margin DESC
LIMIT 100
