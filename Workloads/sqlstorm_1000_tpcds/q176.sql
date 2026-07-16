WITH sales_agg AS (
   SELECT
      s.channel,
      s.state,
      s.date_sk,
      sum(s.quantity) AS total_quantity_sold,
      sum(s.net_profit) AS total_net_profit,
      sum(s.discount_amt) AS total_discount_amount,
      count(distinct s.customer_sk) AS distinct_customers
   FROM (
     SELECT
        cs.cs_sold_date_sk AS date_sk,
        cc.cc_state AS state,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_bill_customer_sk AS customer_sk,
        'catalog' AS channel
     FROM catalog_sales cs
     JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk

     UNION ALL

     SELECT
        ss.ss_sold_date_sk AS date_sk,
        s.s_state AS state,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amt,
        ss.ss_customer_sk AS customer_sk,
        'store' AS channel
     FROM store_sales ss
     JOIN store s ON ss.ss_store_sk = s.s_store_sk

     UNION ALL

     SELECT
        ws.ws_sold_date_sk AS date_sk,
        ca.ca_state AS state,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amt,
        ws.ws_bill_customer_sk AS customer_sk,
        'web' AS channel
     FROM web_sales ws
     JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
     JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   ) s
   GROUP BY s.channel, s.state, s.date_sk
),
returns_agg AS (
   SELECT
      r.channel,
      r.state,
      r.date_sk,
      sum(r.quantity) AS total_quantity_returned,
      sum(r.net_loss) AS total_net_loss
   FROM (
     SELECT
        cr.cr_returned_date_sk AS date_sk,
        cc.cc_state AS state,
        cr.cr_return_quantity AS quantity,
        cr.cr_net_loss AS net_loss,
        'catalog' AS channel
     FROM catalog_returns cr
     JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk

     UNION ALL

     SELECT
        sr.sr_returned_date_sk AS date_sk,
        s.s_state AS state,
        sr.sr_return_quantity AS quantity,
        sr.sr_net_loss AS net_loss,
        'store' AS channel
     FROM store_returns sr
     JOIN store s ON sr.sr_store_sk = s.s_store_sk

     UNION ALL

     SELECT
        wr.wr_returned_date_sk AS date_sk,
        ca.ca_state AS state,
        wr.wr_return_quantity AS quantity,
        wr.wr_net_loss AS net_loss,
        'web' AS channel
     FROM web_returns wr
     JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
   ) r
   GROUP BY r.channel, r.state, r.date_sk
),
sales_with_date AS (
   SELECT
      sa.channel,
      sa.state,
      d.d_year,
      d.d_moy,
      sa.total_quantity_sold,
      sa.total_net_profit,
      sa.total_discount_amount,
      sa.distinct_customers,
      coalesce(ra.total_quantity_returned, 0) AS total_quantity_returned,
      coalesce(ra.total_net_loss, 0) AS total_net_loss
   FROM sales_agg sa
   LEFT JOIN returns_agg ra
     ON sa.channel = ra.channel
    AND sa.state = ra.state
    AND sa.date_sk = ra.date_sk
   JOIN date_dim d ON sa.date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
)
SELECT
   channel,
   state,
   d_year,
   d_moy,
   sum(total_quantity_sold) AS total_qty_sold,
   sum(total_quantity_returned) AS total_qty_returned,
   sum(total_net_profit) AS total_net_profit,
   sum(total_net_loss) AS total_net_loss,
   sum(total_net_profit) - sum(total_net_loss) AS net_margin,
   sum(distinct_customers) AS distinct_customers,
   (sum(total_quantity_returned) / nullif(sum(total_quantity_sold), 0)) AS return_rate,
   avg(total_discount_amount) AS avg_discount_amount,
   lag(sum(total_net_profit) - sum(total_net_loss)) OVER (PARTITION BY channel, state, d_moy ORDER BY d_year) AS prior_year_margin,
   (sum(total_net_profit) - sum(total_net_loss)) - lag(sum(total_net_profit) - sum(total_net_loss)) OVER (PARTITION BY channel, state, d_moy ORDER BY d_year) AS yoy_margin_change,
   rank() OVER (PARTITION BY channel, d_year ORDER BY (sum(total_net_profit) - sum(total_net_loss)) DESC) AS state_margin_rank
FROM sales_with_date
GROUP BY
   channel,
   state,
   d_year,
   d_moy
HAVING sum(total_net_profit) > 0
ORDER BY channel, net_margin DESC, d_year, d_moy
LIMIT 200
