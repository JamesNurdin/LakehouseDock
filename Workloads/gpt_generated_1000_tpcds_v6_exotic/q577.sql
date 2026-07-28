WITH sales_agg AS (
   SELECT
       ss.ss_store_sk,
       ss.ss_sold_date_sk,
       ss.ss_hdemo_sk,
       SUM(ss.ss_net_profit)        AS total_net_profit,
       SUM(ss.ss_quantity)          AS total_qty,
       SUM(ss.ss_net_paid)          AS total_net_paid
   FROM tpcds.store_sales ss
   GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_hdemo_sk
),
returns_agg AS (
   SELECT
       sr.sr_store_sk,
       sr.sr_returned_date_sk,
       SUM(sr.sr_net_loss)          AS total_net_loss,
       SUM(sr.sr_return_quantity)   AS total_return_qty
   FROM tpcds.store_returns sr
   GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
),
inventory_agg AS (
   SELECT
       inv.inv_date_sk,
       SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
   FROM tpcds.inventory inv
   GROUP BY inv.inv_date_sk
),
web_agg AS (
   SELECT
       wr.wr_returned_date_sk,
       wr.wr_refunded_addr_sk,
       SUM(wr.wr_return_amt)       AS total_wr_amt,
       SUM(wr.wr_return_quantity)  AS total_wr_qty
   FROM tpcds.web_returns wr
   GROUP BY wr.wr_returned_date_sk, wr.wr_refunded_addr_sk
)
SELECT
   s.s_store_name,
   d.d_date,
   cp.cp_type,
   ib.ib_lower_bound,
   ib.ib_upper_bound,
   CASE
       WHEN hd.hd_buy_potential = 'HIGH'   THEN 'Premium'
       WHEN hd.hd_buy_potential = 'MEDIUM' THEN 'Standard'
       ELSE                                 'Budget'
   END                                          AS customer_segment,
   (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) AS profit_after_returns,
   (sa.total_qty        - COALESCE(ra.total_return_qty, 0)) AS net_quantity_sold,
   ia.total_qty_on_hand,
   wa.total_wr_amt,
   ca.ca_city,
   RANK() OVER (PARTITION BY d.d_year ORDER BY (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) DESC) AS profit_rank_year
FROM sales_agg sa
JOIN tpcds.store s               ON s.s_store_sk = sa.ss_store_sk
JOIN tpcds.date_dim d            ON d.d_date_sk = sa.ss_sold_date_sk
LEFT JOIN returns_agg ra        ON ra.sr_store_sk = sa.ss_store_sk
                                 AND ra.sr_returned_date_sk = d.d_date_sk
LEFT JOIN tpcds.household_demographics hd ON hd.hd_demo_sk = sa.ss_hdemo_sk
LEFT JOIN tpcds.income_band ib          ON ib.ib_income_band_sk = hd.hd_income_band_sk
LEFT JOIN tpcds.catalog_page cp        ON cp.cp_start_date_sk = d.d_date_sk
LEFT JOIN inventory_agg ia             ON ia.inv_date_sk = d.d_date_sk
LEFT JOIN web_agg wa                   ON wa.wr_returned_date_sk = d.d_date_sk
LEFT JOIN tpcds.customer_address ca   ON ca.ca_address_sk = wa.wr_refunded_addr_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND ib.ib_upper_bound >= 100000
  AND cp.cp_type = 'PROMO'
  AND ca.ca_state = 'CA'
GROUP BY
   s.s_store_name,
   d.d_date,
   cp.cp_type,
   ib.ib_lower_bound,
   ib.ib_upper_bound,
   hd.hd_buy_potential,
   sa.total_net_profit,
   ra.total_net_loss,
   sa.total_qty,
   ra.total_return_qty,
   ia.total_qty_on_hand,
   wa.total_wr_amt,
   ca.ca_city,
   d.d_year
HAVING (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) > 0
ORDER BY profit_rank_year, d.d_date
LIMIT 100
