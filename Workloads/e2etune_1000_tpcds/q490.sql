WITH sales_union AS (
  SELECT
    i.i_item_sk,
    i.i_brand,
    i.i_category,
    cp.cp_department,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_sales_price AS sales_amount,
    cs.cs_order_number AS transaction_id
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cp.cp_type = 'monthly'
    AND cp.cp_catalog_number = 3
    AND cs.cs_sold_date_sk BETWEEN 2450900 AND 2451100

  UNION ALL

  SELECT
    i.i_item_sk,
    i.i_brand,
    i.i_category,
    NULL AS cp_department,
    ss.ss_net_profit AS net_profit,
    ss.ss_ext_sales_price AS sales_amount,
    ss.ss_ticket_number AS transaction_id
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450900 AND 2451100
),

sales_agg AS (
  SELECT
    i_item_sk,
    i_brand,
    i_category,
    MAX(cp_department) AS cp_department,
    SUM(net_profit) AS total_net_profit,
    SUM(sales_amount) AS total_sales_amount,
    COUNT(DISTINCT transaction_id) AS total_transactions
  FROM sales_union
  GROUP BY i_item_sk, i_brand, i_category
),

returns_agg AS (
  SELECT
    i.i_item_sk,
    SUM(wr.wr_return_amt_inc_tax) AS total_returns_amount,
    SUM(wr.wr_net_loss) AS total_returns_loss,
    COUNT(*) AS total_returns_cnt
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2450900 AND 2451100
  GROUP BY i.i_item_sk
)
SELECT
  s.i_item_sk,
  s.i_brand,
  s.i_category,
  s.cp_department,
  s.total_sales_amount,
  s.total_net_profit,
  s.total_transactions,
  COALESCE(r.total_returns_amount, 0) AS total_returns_amount,
  (s.total_net_profit - COALESCE(r.total_returns_amount, 0)) AS adjusted_net_profit,
  RANK() OVER (PARTITION BY s.cp_department ORDER BY (s.total_net_profit - COALESCE(r.total_returns_amount, 0)) DESC) AS dept_profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r ON s.i_item_sk = r.i_item_sk
WHERE s.total_net_profit > 0
ORDER BY s.cp_department, dept_profit_rank
LIMIT 100
