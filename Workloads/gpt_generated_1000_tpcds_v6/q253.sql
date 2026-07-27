WITH j AS (
   SELECT
      cs.cs_quantity,
      cs.cs_sold_date_sk,
      cs.cs_net_paid,
      cs.cs_net_profit,
      ca.ca_state,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      sr.sr_net_loss,
      r.r_reason_id
   FROM catalog_sales cs
   JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN store_returns sr
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
   LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
   WHERE cs.cs_quantity > 2
     AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450500
     AND ib.ib_lower_bound >= 50000
     AND (r.r_reason_id IS NULL OR r.r_reason_id LIKE 'AAAA%')
)
SELECT
   j.ca_state,
   j.ib_lower_bound,
   j.ib_upper_bound,
   SUM(j.cs_net_paid) AS total_sales,
   SUM(j.cs_net_profit) AS total_profit,
   SUM(COALESCE(j.sr_net_loss, 0)) AS total_returns_loss,
   (SUM(j.cs_net_profit) - SUM(COALESCE(j.sr_net_loss, 0))) / NULLIF(SUM(j.cs_net_paid), 0) AS profit_margin,
   RANK() OVER (ORDER BY (SUM(j.cs_net_profit) - SUM(COALESCE(j.sr_net_loss, 0))) DESC) AS profit_margin_rank
FROM j
GROUP BY j.ca_state, j.ib_lower_bound, j.ib_upper_bound
HAVING SUM(j.cs_net_paid) > 10000
ORDER BY profit_margin_rank
LIMIT 20
