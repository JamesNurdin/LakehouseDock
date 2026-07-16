WITH cat_month_agg AS (
  SELECT d.d_year,
         d.d_moy,
         cp.cp_department,
         SUM(cs.cs_net_profit) AS cat_net_profit,
         SUM(cs.cs_quantity) AS cat_quantity,
         COUNT(DISTINCT cs.cs_order_number) AS cat_orders
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND cp.cp_department = 'DEPARTMENT'
    AND cp.cp_catalog_page_number >= 2
  GROUP BY d.d_year, d.d_moy, cp.cp_department
),

web_month_agg AS (
  SELECT d.d_year,
         d.d_moy,
         SUM(ws.ws_net_profit) AS web_net_profit,
         SUM(ws.ws_quantity) AS web_quantity,
         COUNT(DISTINCT ws.ws_order_number) AS web_orders
  FROM web_sales ws
  JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_moy
),

return_month_agg AS (
  SELECT d.d_year,
         d.d_moy,
         SUM(sr.sr_net_loss) AS total_return_loss,
         COUNT(*) AS return_cnt
  FROM store_returns sr
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_moy
)

SELECT 
    ca.d_year,
    ca.d_moy,
    ca.cp_department,
    ca.cat_net_profit,
    COALESCE(wm.web_net_profit, 0) AS web_net_profit,
    COALESCE(rm.total_return_loss, 0) AS total_return_loss,
    (ca.cat_net_profit + COALESCE(wm.web_net_profit, 0) - COALESCE(rm.total_return_loss, 0)) AS net_contribution,
    RANK() OVER (PARTITION BY ca.d_year, ca.d_moy ORDER BY ca.cat_net_profit DESC) AS dept_profit_rank
FROM cat_month_agg ca
LEFT JOIN web_month_agg wm
  ON ca.d_year = wm.d_year AND ca.d_moy = wm.d_moy
LEFT JOIN return_month_agg rm
  ON ca.d_year = rm.d_year AND ca.d_moy = rm.d_moy
ORDER BY ca.d_year, ca.d_moy, dept_profit_rank
