WITH
  promo_sampled AS (
    SELECT p_promo_sk, p_cost
    FROM promotion TABLESAMPLE BERNOULLI (10)
    WHERE p_discount_active = 'Y'
  ),
  sales_base AS (
    SELECT
      ss.ss_ticket_number AS ticket,
      ss.ss_quantity,
      ss.ss_sales_price,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      p.p_cost,
      td.t_hour,
      cd.cd_gender,
      ca.ca_state
    FROM store_sales ss
    LEFT OUTER JOIN promo_sampled p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_quantity > 5
      AND ss.ss_sales_price > (
        SELECT MAX(p_cost)
        FROM promotion
        WHERE p_discount_active = 'Y'
      )
      AND td.t_hour BETWEEN 8 AND 18
  ),
  returns_base AS (
    SELECT
      sr.sr_ticket_number AS ticket,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss,
      td.t_hour,
      cd.cd_gender,
      ca.ca_state
    FROM store_returns sr
    JOIN time_dim td
      ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 20
      AND td.t_hour BETWEEN 8 AND 18
  ),
  agg_sales AS (
    SELECT
      ticket,
      SUM(ss_ext_sales_price) AS sales_total,
      AVG(ss_net_profit) AS sales_avg_profit,
      COUNT(*) AS sales_cnt
    FROM sales_base
    GROUP BY ticket
  ),
  agg_returns AS (
    SELECT
      ticket,
      SUM(sr_return_amt) AS returns_total,
      AVG(sr_net_loss) AS returns_avg_loss,
      COUNT(*) AS returns_cnt
    FROM returns_base
    GROUP BY ticket
  ),
  full_joined AS (
    SELECT
      COALESCE(a.ticket, r.ticket) AS ticket,
      a.sales_total,
      a.sales_avg_profit,
      a.sales_cnt,
      r.returns_total,
      r.returns_avg_loss,
      r.returns_cnt
    FROM agg_sales a
    FULL OUTER JOIN agg_returns r
      ON a.ticket = r.ticket
  ),
  unioned AS (
    SELECT ticket, sales_total AS amount, sales_avg_profit AS metric FROM agg_sales
    UNION
    SELECT ticket, returns_total AS amount, returns_avg_loss AS metric FROM agg_returns
  ),
  final_aggregated AS (
    SELECT
      u.ticket,
      SUM(u.amount) AS total_amount,
      AVG(u.metric) AS avg_metric,
      COUNT(*) AS rows_cnt
    FROM unioned u
    GROUP BY u.ticket
  ),
  tickets_no_returns AS (
    SELECT ss_ticket_number AS ticket
    FROM store_sales
    EXCEPT
    SELECT sr_ticket_number FROM store_returns
  )
SELECT
  f.ticket,
  f.total_amount,
  f.avg_metric,
  f.rows_cnt
FROM final_aggregated f
WHERE f.ticket IN (SELECT ticket FROM tickets_no_returns)
ORDER BY f.total_amount DESC
LIMIT 100
