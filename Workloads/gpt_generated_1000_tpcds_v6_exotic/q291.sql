WITH
  sales_base AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_customer_sk,
      ss.ss_net_profit,
      ss.ss_ext_sales_price,
      td.t_time_id,
      c.c_email_address,
      c.c_first_name,
      c.c_last_name,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
      REGEXP_EXTRACT(c.c_email_address, '@([^@]+)$', 1) AS email_domain
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '@example\\.com$')
      AND c.c_last_name LIKE 'S%'
  ),
  returns_agg AS (
    SELECT
      sr.sr_ticket_number,
      SUM(sr.sr_net_loss) AS return_loss
    FROM store_returns sr
    GROUP BY sr.sr_ticket_number
  ),
  customer_agg AS (
    SELECT
      sb.ss_customer_sk,
      sb.full_name,
      sb.email_domain,
      SUM(sb.ss_net_profit) AS total_profit,
      SUM(sb.ss_ext_sales_price) AS total_sales,
      SUM(COALESCE(ra.return_loss, 0)) AS total_returns_loss,
      SUM(sb.ss_net_profit) - SUM(COALESCE(ra.return_loss, 0)) AS net_after_returns,
      COUNT(DISTINCT sb.ss_ticket_number) AS distinct_transactions
    FROM sales_base sb
    LEFT JOIN returns_agg ra ON sb.ss_ticket_number = ra.sr_ticket_number
    GROUP BY sb.ss_customer_sk, sb.full_name, sb.email_domain
  )
SELECT
  ca.ss_customer_sk,
  ca.full_name,
  ca.email_domain,
  ca.total_sales,
  ca.total_profit,
  ca.total_returns_loss,
  ca.net_after_returns,
  CASE WHEN ca.net_after_returns > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
  RANK() OVER (ORDER BY ca.net_after_returns DESC) AS profit_rank,
  COUNT(DISTINCT ca.email_domain) OVER () AS distinct_domain_count
FROM customer_agg ca
ORDER BY ca.net_after_returns DESC
LIMIT 100
