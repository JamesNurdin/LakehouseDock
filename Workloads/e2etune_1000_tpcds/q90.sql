WITH filtered_sales AS (
  SELECT ss.*
  FROM store_sales ss
  WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
),
filtered_returns AS (
  SELECT sr.*
  FROM store_returns sr
  WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2459999
),
joined AS (
  SELECT s.s_store_name,
         s.s_state,
         r.r_reason_desc,
         ss.ss_quantity,
         ss.ss_net_paid_inc_tax,
         ss.ss_net_profit,
         sr.sr_return_quantity,
         (sr.sr_refunded_cash + sr.sr_store_credit + sr.sr_reversed_charge) AS return_amount,
         sr.sr_net_loss,
         ca_s.ca_country AS sales_country,
         ca_r.ca_country AS return_country
  FROM filtered_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN filtered_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
                         AND ss.ss_item_sk = sr.sr_item_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN customer_address ca_s ON ss.ss_addr_sk = ca_s.ca_address_sk
  LEFT JOIN customer_address ca_r ON sr.sr_addr_sk = ca_r.ca_address_sk
  WHERE s.s_state IN ('CA','TX','NY')
    AND ca_s.ca_country = 'United States'
    AND ca_r.ca_country = 'United States'
    AND sr.sr_store_sk = s.s_store_sk
),
agg AS (
  SELECT s_store_name,
         s_state,
         r_reason_desc,
         SUM(ss_quantity) AS total_sales_qty,
         SUM(ss_net_paid_inc_tax) AS total_sales_amount,
         SUM(ss_net_profit) AS total_sales_profit,
         SUM(sr_return_quantity) AS total_return_qty,
         SUM(return_amount) AS total_return_amount,
         SUM(sr_net_loss) AS total_return_loss,
         (SUM(ss_net_profit) - COALESCE(SUM(sr_net_loss), 0)) AS net_profit_after_returns,
         ROUND((SUM(sr_return_quantity) * 100.0) / NULLIF(SUM(ss_quantity), 0), 2) AS return_rate_pct
  FROM joined
  GROUP BY s_store_name, s_state, r_reason_desc
  HAVING SUM(ss_net_paid_inc_tax) > 5000
)
SELECT s_store_name,
       s_state,
       r_reason_desc,
       total_sales_qty,
       total_sales_amount,
       total_sales_profit,
       total_return_qty,
       total_return_amount,
       total_return_loss,
       net_profit_after_returns,
       return_rate_pct,
       RANK() OVER (PARTITION BY s_store_name ORDER BY net_profit_after_returns DESC) AS profit_rank_by_reason
FROM agg
ORDER BY net_profit_after_returns DESC
LIMIT 20
