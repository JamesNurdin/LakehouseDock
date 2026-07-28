WITH
  /* Eligible stores using a set operation (UNION) */
  eligible_stores AS (
    SELECT s_store_sk FROM store WHERE s_state = 'TX'
    UNION
    SELECT s_store_sk FROM store WHERE s_market_id = 5
  ),
  /* Aggregate store returns per store, year and hour */
  store_return_agg AS (
    SELECT
      sr.sr_store_sk,
      d_ret.d_year,
      t_ret.t_hour,
      SUM(sr.sr_net_loss) AS total_sr_net_loss,
      COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    WHERE d_ret.d_year = 2001
    GROUP BY sr.sr_store_sk, d_ret.d_year, t_ret.t_hour
  ),
  /* Aggregate web returns per year and hour */
  web_return_agg AS (
    SELECT
      d_web.d_year,
      t_web.t_hour,
      SUM(wr.wr_net_loss) AS total_wr_net_loss,
      COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM web_returns wr
    JOIN date_dim d_web ON wr.wr_returned_date_sk = d_web.d_date_sk
    JOIN time_dim t_web ON wr.wr_returned_time_sk = t_web.t_time_sk
    WHERE d_web.d_year = 2001
    GROUP BY d_web.d_year, t_web.t_hour
  )
SELECT DISTINCT
  s.s_store_name,
  ca_ret_addr.ca_city AS return_city,
  d_ret.d_date,
  t_ret.t_hour,
  agg_sr.total_sr_net_loss,
  agg_wr.total_wr_net_loss,
  CASE WHEN agg_sr.total_sr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
  agg_sr.distinct_tickets,
  agg_wr.distinct_orders,
  CASE WHEN ca_wr_refund.ca_country = 'United States' THEN 'Domestic' ELSE 'International' END AS refund_address_type,
  (SELECT COUNT(*) FROM call_center WHERE cc_state = 'CA') AS ca_call_center_count
FROM store_returns sr
JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
JOIN customer_address ca_ret_addr ON sr.sr_addr_sk = ca_ret_addr.ca_address_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_web ON wr.wr_returned_time_sk = t_web.t_time_sk
JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
JOIN eligible_stores es ON s.s_store_sk = es.s_store_sk
JOIN store_return_agg agg_sr ON agg_sr.sr_store_sk = s.s_store_sk
                           AND agg_sr.d_year = d_ret.d_year
                           AND agg_sr.t_hour = t_ret.t_hour
JOIN web_return_agg agg_wr ON agg_wr.d_year = d_ret.d_year
                          AND agg_wr.t_hour = t_ret.t_hour
ORDER BY loss_category DESC, agg_sr.total_sr_net_loss DESC
LIMIT 100
