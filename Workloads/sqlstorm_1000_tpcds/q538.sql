WITH sales AS (
   SELECT
      d.d_year AS year,
      'catalog' AS channel,
      i.i_category,
      i.i_brand,
      cs.cs_order_number AS order_number,
      cs.cs_net_paid AS net_paid,
      cs.cs_net_profit AS net_profit,
      cs.cs_bill_customer_sk AS customer_sk
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
   UNION ALL
   SELECT
      d.d_year,
      'store',
      i.i_category,
      i.i_brand,
      ss.ss_ticket_number AS order_number,
      ss.ss_net_paid,
      ss.ss_net_profit,
      ss.ss_customer_sk
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
   UNION ALL
   SELECT
      d.d_year,
      'web',
      i.i_category,
      i.i_brand,
      ws.ws_order_number,
      ws.ws_net_paid,
      ws.ws_net_profit,
      ws.ws_bill_customer_sk
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
), returns_raw AS (
   SELECT
      d.d_year AS year,
      'catalog' AS channel,
      cr.cr_order_number AS order_number,
      cr.cr_net_loss AS net_loss
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
   UNION ALL
   SELECT
      d.d_year,
      'store',
      sr.sr_ticket_number,
      sr.sr_net_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
   UNION ALL
   SELECT
      d.d_year,
      'web',
      wr.wr_order_number,
      wr.wr_net_loss
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
), returns AS (
   SELECT
      year,
      channel,
      order_number,
      SUM(net_loss) AS net_loss
   FROM returns_raw
   GROUP BY year, channel, order_number
), aggregated AS (
   SELECT
      s.year,
      s.channel,
      s.i_category AS category,
      s.i_brand AS brand,
      SUM(s.net_paid) AS total_net_paid,
      SUM(s.net_profit) AS total_net_profit,
      COALESCE(SUM(r.net_loss), 0) AS total_net_loss,
      SUM(s.net_paid) - COALESCE(SUM(r.net_loss), 0) AS net_revenue,
      SUM(s.net_profit) - COALESCE(SUM(r.net_loss), 0) AS net_profit_adj,
      AVG(s.net_paid) AS avg_net_paid,
      approx_percentile(s.net_profit, 0.5) AS median_net_profit,
      approx_distinct(s.customer_sk) AS distinct_customers,
      approx_distinct(s.order_number) AS distinct_orders
   FROM sales s
   LEFT JOIN returns r
      ON s.year = r.year
      AND s.channel = r.channel
      AND s.order_number = r.order_number
   GROUP BY s.year, s.channel, s.i_category, s.i_brand
)
SELECT
   a.year,
   a.channel,
   a.category,
   a.brand,
   a.total_net_paid,
   a.total_net_profit,
   a.total_net_loss,
   a.net_revenue,
   a.net_profit_adj,
   a.avg_net_paid,
   a.median_net_profit,
   a.distinct_customers,
   a.distinct_orders,
   ROW_NUMBER() OVER (PARTITION BY a.year, a.channel, a.category ORDER BY a.net_revenue DESC) AS brand_rank_in_category
FROM aggregated a
ORDER BY a.year, a.channel, a.category, brand_rank_in_category
