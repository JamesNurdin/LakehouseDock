WITH joined AS (
  SELECT
    sr.sr_store_sk,
    sr.sr_ticket_number,
    sr.sr_net_loss,
    sr.sr_return_tax,
    sr.sr_fee,
    ss.ss_ext_sales_price,
    ss.ss_wholesale_cost,
    ss.ss_coupon_amt,
    r.r_reason_desc,
    r.r_reason_sk
  FROM store_returns sr
  JOIN store_sales ss
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  WHERE sr.sr_return_tax > 5
    AND sr.sr_fee BETWEEN 5 AND 60
    AND ss.ss_wholesale_cost > 20
    AND r.r_reason_sk IN (4, 6, 11, 18)
),
agg AS (
  SELECT
    r_reason_desc,
    sr_store_sk,
    SUM(sr_net_loss) AS total_net_loss,
    SUM(ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT sr_ticket_number) AS distinct_tickets,
    AVG(ss_coupon_amt) AS avg_coupon_amt
  FROM joined
  GROUP BY r_reason_desc, sr_store_sk
)
SELECT
  r_reason_desc,
  sr_store_sk,
  total_net_loss,
  total_sales,
  distinct_tickets,
  avg_coupon_amt,
  CASE WHEN total_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
  SUM(total_net_loss) OVER (
    PARTITION BY CASE WHEN total_net_loss > 1000 THEN 'High' ELSE 'Low' END
    ORDER BY total_net_loss DESC
  ) AS cum_net_loss_by_category,
  RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
  AVG(total_net_loss) OVER () AS avg_net_loss_overall
FROM agg
WHERE total_net_loss > 200
ORDER BY total_net_loss DESC
LIMIT 100
