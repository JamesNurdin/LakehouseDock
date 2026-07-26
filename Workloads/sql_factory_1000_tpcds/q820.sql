WITH loss_by_market_warehouse AS (
  SELECT 
    cc.cc_mkt_class,
    cc.cc_mkt_desc,
    cr.cr_warehouse_sk,
    d.d_year,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount
  FROM catalog_returns cr
  INNER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  INNER JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  GROUP BY cc.cc_mkt_class, cc.cc_mkt_desc, cr.cr_warehouse_sk, d.d_year
),
market_totals AS (
  SELECT 
    cc_mkt_class,
    cc_mkt_desc,
    d_year,
    SUM(total_net_loss) AS market_total_net_loss
  FROM loss_by_market_warehouse
  GROUP BY cc_mkt_class, cc_mkt_desc, d_year
)
SELECT 
  l.cc_mkt_class,
  l.cc_mkt_desc,
  l.d_year,
  l.cr_warehouse_sk,
  l.total_net_loss,
  l.total_return_amount,
  CASE 
    WHEN l.total_net_loss > 500000 THEN 'Critical'
    WHEN l.total_net_loss > 200000 THEN 'High'
    WHEN l.total_net_loss > 50000 THEN 'Medium'
    ELSE 'Low'
  END AS loss_severity,
  l.total_net_loss / mt.market_total_net_loss AS warehouse_net_loss_pct,
  DENSE_RANK() OVER (PARTITION BY l.d_year ORDER BY l.total_net_loss DESC) AS yearly_market_rank,
  RANK() OVER (PARTITION BY l.cc_mkt_class, l.d_year ORDER BY l.total_net_loss DESC) AS market_warehouse_rank
FROM loss_by_market_warehouse l
INNER JOIN market_totals mt 
  ON l.cc_mkt_class = mt.cc_mkt_class
 AND l.cc_mkt_desc = mt.cc_mkt_desc
 AND l.d_year = mt.d_year
ORDER BY l.d_year, l.total_net_loss DESC
LIMIT 50
