WITH sales_by_demo AS (
  SELECT
    cd.cd_demo_sk,
    cd.cd_credit_rating,
    cd.cd_gender,
    cd.cd_marital_status,
    s.s_state,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
  FROM store_sales ss
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  WHERE cd.cd_credit_rating IN ('Good', 'Low Risk')
    AND cd.cd_gender = 'F'
  GROUP BY
    cd.cd_demo_sk,
    cd.cd_credit_rating,
    cd.cd_gender,
    cd.cd_marital_status,
    s.s_state
),
returns_by_demo AS (
  SELECT
    cd.cd_demo_sk,
    cd.cd_credit_rating,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_quantity) AS total_return_qty
  FROM web_returns wr
  JOIN customer_demographics cd
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_credit_rating IN ('Good', 'Low Risk')
    AND cd.cd_gender = 'F'
  GROUP BY
    cd.cd_demo_sk,
    cd.cd_credit_rating,
    cd.cd_gender,
    cd.cd_marital_status
)
SELECT
  sbd.s_state,
  sbd.cd_credit_rating,
  sbd.cd_gender,
  sbd.cd_marital_status,
  sbd.total_net_profit,
  COALESCE(rbd.total_net_loss, 0) AS total_net_loss,
  (sbd.total_net_profit - COALESCE(rbd.total_net_loss, 0)) AS net_profit_after_returns,
  ROUND(((sbd.total_net_profit - COALESCE(rbd.total_net_loss, 0)) / NULLIF(sbd.total_net_profit, 0)) * 100, 2) AS profit_margin_pct,
  RANK() OVER (ORDER BY (sbd.total_net_profit - COALESCE(rbd.total_net_loss, 0)) DESC) AS profit_rank
FROM sales_by_demo sbd
LEFT JOIN returns_by_demo rbd
  ON sbd.cd_demo_sk = rbd.cd_demo_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100
