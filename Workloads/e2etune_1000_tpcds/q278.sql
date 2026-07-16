WITH catalog_agg AS (
  SELECT
    d.d_year,
    d.d_moy AS month_num,
    cs.cs_warehouse_sk,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_list_price) AS avg_list_price,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE cs.cs_warehouse_sk IN (14, 2, 7)
    AND cs.cs_quantity > 20
    AND cs.cs_list_price > 120
  GROUP BY d.d_year, d.d_moy, cs.cs_warehouse_sk
),

catalog_rank AS (
  SELECT
    *,
    RANK() OVER (PARTITION BY d_year, month_num ORDER BY total_net_profit DESC) AS warehouse_rank
  FROM catalog_agg
),

returns_agg AS (
  SELECT
    d.d_year,
    d.d_moy AS month_num,
    r.r_reason_desc,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_amt) AS total_return_amt,
    COUNT(*) AS return_cnt
  FROM web_returns wr
  JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  WHERE wr.wr_return_amt > 100
  GROUP BY d.d_year, d.d_moy, r.r_reason_desc
),

returns_rank AS (
  SELECT
    *,
    RANK() OVER (PARTITION BY d_year, month_num ORDER BY total_net_loss DESC) AS reason_rank
  FROM returns_agg
)

SELECT
  ca.d_year,
  ca.month_num,
  ca.cs_warehouse_sk AS warehouse_sk,
  ca.total_net_profit,
  ca.total_sales,
  ca.avg_list_price,
  ca.warehouse_rank,
  rr.r_reason_desc,
  rr.total_net_loss,
  rr.total_return_amt,
  rr.return_cnt,
  rr.reason_rank
FROM catalog_rank ca
LEFT JOIN returns_rank rr
  ON ca.d_year = rr.d_year
  AND ca.month_num = rr.month_num
WHERE ca.warehouse_rank <= 5
  AND rr.reason_rank = 1
ORDER BY ca.d_year, ca.month_num, ca.warehouse_rank
