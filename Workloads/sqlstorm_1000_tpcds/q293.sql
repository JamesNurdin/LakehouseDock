WITH unified AS (
   SELECT
      ss_sold_date_sk AS date_sk,
      'store' AS channel,
      ss_store_sk AS store_sk,
      NULL AS call_center_sk,
      NULL AS web_site_sk,
      ss_quantity AS quantity,
      ss_net_paid AS net_paid,
      ss_net_profit AS net_profit,
      NULL AS net_loss
   FROM store_sales
   UNION ALL
   SELECT
      cs_sold_date_sk,
      'catalog',
      NULL,
      cs_call_center_sk,
      NULL,
      cs_quantity,
      cs_net_paid,
      cs_net_profit,
      NULL
   FROM catalog_sales
   UNION ALL
   SELECT
      ws_sold_date_sk,
      'web',
      NULL,
      NULL,
      ws_web_site_sk,
      ws_quantity,
      ws_net_paid,
      ws_net_profit,
      NULL
   FROM web_sales
   UNION ALL
   SELECT
      sr_returned_date_sk,
      'store',
      sr_store_sk,
      NULL,
      NULL,
      sr_return_quantity,
      -sr_return_amt,
      NULL,
      sr_net_loss
   FROM store_returns
   UNION ALL
   SELECT
      cr_returned_date_sk,
      'catalog',
      NULL,
      cr_call_center_sk,
      NULL,
      cr_return_quantity,
      -cr_return_amount,
      NULL,
      cr_net_loss
   FROM catalog_returns
   UNION ALL
   SELECT
      wr_returned_date_sk,
      'web',
      NULL,
      NULL,
      NULL,
      wr_return_quantity,
      -wr_return_amt,
      NULL,
      wr_net_loss
   FROM web_returns
),
joined AS (
   SELECT
      u.channel,
      COALESCE(st.s_store_name, cc.cc_name, ws.web_name, 'All Channels') AS entity_name,
      d.d_year,
      d.d_month_seq,
      SUM(u.quantity) AS total_quantity,
      SUM(u.net_paid) AS total_net_paid,
      SUM(COALESCE(u.net_profit, 0)) AS total_net_profit,
      SUM(COALESCE(u.net_loss, 0)) AS total_net_loss,
      (SUM(u.net_paid) - SUM(COALESCE(u.net_loss, 0))) AS net_revenue
   FROM unified u
   LEFT JOIN store st ON u.store_sk = st.s_store_sk
   LEFT JOIN call_center cc ON u.call_center_sk = cc.cc_call_center_sk
   LEFT JOIN web_site ws ON u.web_site_sk = ws.web_site_sk
   JOIN date_dim d ON u.date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
   GROUP BY
      u.channel,
      COALESCE(st.s_store_name, cc.cc_name, ws.web_name, 'All Channels'),
      d.d_year,
      d.d_month_seq
),
final AS (
   SELECT
      channel,
      entity_name,
      d_year,
      d_month_seq,
      total_quantity,
      total_net_paid,
      total_net_profit,
      total_net_loss,
      net_revenue,
      RANK() OVER (PARTITION BY d_year ORDER BY net_revenue DESC) AS revenue_rank_year,
      SUM(net_revenue) OVER (PARTITION BY channel ORDER BY d_year, d_month_seq ROWS UNBOUNDED PRECEDING) AS cumulative_revenue,
      ROUND(AVG(total_net_profit) OVER (PARTITION BY channel ORDER BY d_year, d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_profit_3mo
   FROM joined
)
SELECT *
FROM final
ORDER BY channel, d_year, d_month_seq
