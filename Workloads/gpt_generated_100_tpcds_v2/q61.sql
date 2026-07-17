WITH monthly_store_loss AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    SUM(sr.sr_net_loss) AS total_net_loss
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
),
monthly_store_loss_with_avg AS (
  SELECT
    ms.*, 
    AVG(ms.total_net_loss) OVER (
      PARTITION BY ms.s_store_id 
      ORDER BY ms.d_year, ms.d_month_seq 
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3_months,
    RANK() OVER (
      PARTITION BY ms.d_year 
      ORDER BY ms.total_net_loss DESC
    ) AS store_yearly_rank,
    ROW_NUMBER() OVER (
      PARTITION BY ms.s_store_id 
      ORDER BY ms.d_year, ms.d_month_seq DESC
    ) AS month_desc_rownum
  FROM monthly_store_loss ms
)
SELECT
  s.s_store_id,
  s.s_store_name,
  s.d_year,
  s.d_month_seq,
  s.total_net_loss,
  s.moving_avg_3_months,
  CASE WHEN s.moving_avg_3_months > 1000 THEN 'High' ELSE 'Normal' END AS net_loss_category,
  s.store_yearly_rank,
  s.month_desc_rownum
FROM monthly_store_loss_with_avg s
ORDER BY s.d_year, s.d_month_seq, s.total_net_loss DESC
LIMIT 100
