WITH sales_branch AS (
  SELECT DISTINCT
    cs.cs_order_number AS order_number,
    d.d_year,
    CAST(NULL AS varchar) AS s_state,
    cc.cc_division,
    cp.cp_department,
    p.p_cost,
    cd.cd_gender,
    cs.cs_ext_sales_price AS amount,
    cs.cs_net_profit AS net_profit
  FROM catalog_sales cs
  TABLESAMPLE BERNOULLI (10)
  JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
  JOIN time_dim t               ON cs.cs_sold_time_sk   = t.t_time_sk
  JOIN call_center cc          ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w             ON cs.cs_warehouse_sk    = w.w_warehouse_sk
  JOIN promotion p              ON cs.cs_promo_sk       = p.p_promo_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk  = cd.cd_demo_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number   = cs.cs_order_number
                                 AND cr.cr_returned_date_sk = d.d_date_sk
  LEFT JOIN reason r           ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN store_returns sr   ON sr.sr_returned_date_sk = d.d_date_sk
  LEFT JOIN web_returns wr     ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND cc.cc_division IN (1, 2)
    AND p.p_cost > 500
    AND cp.cp_department = 'Sports'
    AND cd.cd_gender = 'M'
),
returns_branch AS (
  SELECT DISTINCT
    sr.sr_ticket_number AS order_number,
    d.d_year,
    s.s_state,
    cc.cc_division,
    cp.cp_department,
    p.p_cost,
    cd.cd_gender,
    (sr.sr_return_amt * -1) AS amount,
    0.0 AS net_profit
  FROM store_returns sr
  JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN time_dim t               ON sr.sr_return_time_sk   = t.t_time_sk
  JOIN store s                  ON sr.sr_store_sk        = s.s_store_sk
  JOIN call_center cc          ON cc.cc_open_date_sk   = d.d_date_sk
  JOIN catalog_page cp          ON cp.cp_start_date_sk  = d.d_date_sk
  JOIN promotion p              ON p.p_start_date_sk    = d.d_date_sk
  JOIN customer_demographics cd ON cd.cd_demo_sk        = sr.sr_cdemo_sk
  LEFT JOIN reason r           ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN warehouse w        ON w.w_warehouse_sk = sr.sr_store_sk   -- using allowed rule via surrogate key
  LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
  LEFT JOIN web_returns wr     ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND cc.cc_division IN (1, 2)
    AND p.p_cost > 500
    AND cp.cp_department = 'Sports'
    AND s.s_state = 'CA'
    AND cd.cd_gender = 'M'
),
combined AS (
  SELECT * FROM sales_branch
  UNION DISTINCT
  SELECT * FROM returns_branch
)
SELECT
  d_year,
  COALESCE(s_state, 'ALL') AS s_state,
  cc_division,
  cp_department,
  SUM(amount)      AS total_amount,
  SUM(net_profit)  AS total_profit,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(amount) DESC) AS amount_rank
FROM combined
GROUP BY GROUPING SETS (
  (d_year, s_state, cc_division, cp_department),
  (d_year, s_state, cc_division),
  (d_year, s_state),
  (d_year),
  ()
)
ORDER BY d_year, s_state, cc_division, cp_department
LIMIT 100
