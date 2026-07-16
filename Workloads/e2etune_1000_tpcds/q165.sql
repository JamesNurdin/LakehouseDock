WITH latest_quarter AS (
  SELECT MAX(d_fy_quarter_seq) AS fq
  FROM date_dim
  WHERE d_current_year = 'Y'
),

sales_agg AS (
  SELECT
    ss.ss_store_sk AS store_sk,
    ss.ss_hdemo_sk AS hdemo_sk,
    d.d_fy_quarter_seq AS quarter_seq,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ss.ss_ext_sales_price) AS store_sales_amount,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  CROSS JOIN latest_quarter lq
  WHERE d.d_fy_quarter_seq = lq.fq
  GROUP BY ss.ss_store_sk, ss.ss_hdemo_sk, d.d_fy_quarter_seq
),

returns_agg AS (
  SELECT
    wr.wr_refunded_hdemo_sk AS hdemo_sk,
    d.d_fy_quarter_seq AS quarter_seq,
    SUM(wr.wr_net_loss) AS returns_net_loss,
    SUM(wr.wr_return_amt) AS returns_amount,
    COUNT(*) AS returns_cnt
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  CROSS JOIN latest_quarter lq
  WHERE d.d_fy_quarter_seq = lq.fq
    AND r.r_reason_desc = 'Damaged'
  GROUP BY wr.wr_refunded_hdemo_sk, d.d_fy_quarter_seq
),

store_with_demo AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_state,
    d.hd_income_band_sk,
    sa.store_net_profit,
    sa.store_sales_amount,
    sa.sales_cnt,
    COALESCE(ra.returns_net_loss, 0) AS returns_net_loss,
    COALESCE(ra.returns_amount, 0) AS returns_amount,
    COALESCE(ra.returns_cnt, 0) AS returns_cnt
  FROM sales_agg sa
  JOIN store s ON sa.store_sk = s.s_store_sk
  JOIN household_demographics d ON sa.hdemo_sk = d.hd_demo_sk
  LEFT JOIN returns_agg ra ON d.hd_demo_sk = ra.hdemo_sk AND sa.quarter_seq = ra.quarter_seq
  WHERE s.s_closed_date_sk IS NULL
),

store_ranked AS (
  SELECT
    swd.s_store_name,
    swd.s_state,
    swd.hd_income_band_sk,
    swd.store_net_profit,
    swd.returns_net_loss,
    (swd.store_net_profit - swd.returns_net_loss) AS net_profit_after_returns,
    RANK() OVER (PARTITION BY swd.hd_income_band_sk ORDER BY (swd.store_net_profit - swd.returns_net_loss) DESC) AS rank_in_income_band
  FROM store_with_demo swd
)

SELECT
  sr.s_store_name,
  sr.s_state,
  sr.hd_income_band_sk,
  ROUND(sr.store_net_profit, 2) AS store_net_profit,
  ROUND(sr.returns_net_loss, 2) AS returns_net_loss,
  ROUND(sr.net_profit_after_returns, 2) AS net_profit_after_returns,
  sr.rank_in_income_band
FROM store_ranked sr
WHERE sr.rank_in_income_band <= 5
ORDER BY sr.hd_income_band_sk, sr.rank_in_income_band
