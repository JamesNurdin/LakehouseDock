WITH store_sales_agg AS (
  SELECT
    s.s_division_name,
    cd.cd_gender,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt,
    AVG(ss.ss_quantity) AS avg_quantity
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_purchase_estimate >= 1500
    AND cd.cd_education_status = 'College'
  GROUP BY s.s_division_name, cd.cd_gender
),
web_return_agg AS (
  SELECT
    cd.cd_gender,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(wr.wr_return_quantity) AS avg_return_qty
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_purchase_estimate >= 1500
    AND cd.cd_education_status = 'College'
  GROUP BY cd.cd_gender
)
SELECT
  sa.s_division_name,
  sa.cd_gender,
  sa.total_net_profit,
  sa.sales_cnt,
  ra.total_net_loss,
  ra.return_cnt,
  (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) AS net_performance,
  RANK() OVER (ORDER BY (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) DESC) AS perf_rank
FROM store_sales_agg sa
LEFT JOIN web_return_agg ra ON sa.cd_gender = ra.cd_gender
ORDER BY net_performance DESC
LIMIT 50
