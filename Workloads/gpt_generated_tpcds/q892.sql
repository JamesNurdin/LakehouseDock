SELECT
   s.s_store_name,
   d.d_year,
   d.d_month_seq,
   ca.ca_state,
   cd.cd_gender,
   SUM(ss.ss_quantity) AS total_quantity_sold,
   SUM(ss.ss_net_paid) AS total_sales_amount,
   SUM(ss.ss_net_profit) AS total_net_profit,
   COALESCE(SUM(r.sr_return_quantity), 0) AS total_return_quantity,
   COALESCE(SUM(r.sr_return_amt), 0) AS total_return_amount,
   CASE WHEN SUM(ss.ss_net_paid) = 0 THEN 0
        ELSE COALESCE(SUM(r.sr_return_amt), 0) / SUM(ss.ss_net_paid) END AS return_rate,
   CASE WHEN SUM(ss.ss_quantity) = 0 THEN 0
        ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_quantity) END AS avg_profit_per_item
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns r
  ON ss.ss_ticket_number = r.sr_ticket_number
  AND ss.ss_item_sk = r.sr_item_sk
WHERE d.d_date >= DATE '2022-01-01'
  AND d.d_date < DATE '2023-01-01'
GROUP BY s.s_store_name, d.d_year, d.d_month_seq, ca.ca_state, cd.cd_gender
ORDER BY s.s_store_name, d.d_year, d.d_month_seq, ca.ca_state, cd.cd_gender
