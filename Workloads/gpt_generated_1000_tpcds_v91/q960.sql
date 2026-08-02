WITH sales_data AS (
  SELECT
    s.s_store_name,
    i.i_category,
    d_sales.d_year,
    d_sales.d_month_seq,
    p.p_promo_name,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_sales_profit
  FROM store_sales ss
  JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  GROUP BY
    s.s_store_name,
    i.i_category,
    d_sales.d_year,
    d_sales.d_month_seq,
    p.p_promo_name
),

returns_data AS (
  SELECT
    s.s_store_name,
    i.i_category,
    d_ret.d_year,
    d_ret.d_month_seq,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    COUNT(*) AS store_return_count,
    COUNT(DISTINCT r.r_reason_desc) AS distinct_return_reasons
  FROM store_returns sr
  JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  GROUP BY
    s.s_store_name,
    i.i_category,
    d_ret.d_year,
    d_ret.d_month_seq
),

web_returns_data AS (
  SELECT
    i.i_category,
    d_wr.d_year,
    d_wr.d_month_seq,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(*) AS web_return_count
  FROM web_returns wr
  JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  GROUP BY
    i.i_category,
    d_wr.d_year,
    d_wr.d_month_seq
),

call_center_data AS (
  SELECT
    cc.cc_name,
    d_cc.d_year,
    d_cc.d_month_seq,
    COUNT(*) AS call_center_closed_count
  FROM call_center cc
  JOIN date_dim d_cc ON cc.cc_closed_date_sk = d_cc.d_date_sk
  GROUP BY
    cc.cc_name,
    d_cc.d_year,
    d_cc.d_month_seq
)

SELECT
  sd.s_store_name,
  sd.i_category,
  sd.d_year,
  sd.d_month_seq,
  sd.p_promo_name,
  sd.total_sales_amount,
  sd.total_sales_profit,
  COALESCE(rd.total_store_return_loss, 0) AS total_store_return_loss,
  COALESCE(rd.store_return_count, 0) AS store_return_count,
  COALESCE(rd.distinct_return_reasons, 0) AS distinct_return_reasons,
  COALESCE(wrd.total_web_return_loss, 0) AS total_web_return_loss,
  COALESCE(wrd.web_return_count, 0) AS web_return_count,
  COALESCE(ccd.call_center_closed_count, 0) AS call_center_closed_count
FROM sales_data sd
LEFT JOIN returns_data rd
  ON rd.s_store_name = sd.s_store_name
  AND rd.i_category = sd.i_category
  AND rd.d_year = sd.d_year
  AND rd.d_month_seq = sd.d_month_seq
FULL OUTER JOIN call_center_data ccd
  ON ccd.d_year = sd.d_year
  AND ccd.d_month_seq = sd.d_month_seq
LEFT JOIN web_returns_data wrd
  ON wrd.i_category = sd.i_category
  AND wrd.d_year = sd.d_year
  AND wrd.d_month_seq = sd.d_month_seq
ORDER BY
  sd.total_sales_amount DESC,
  sd.d_year,
  sd.d_month_seq
LIMIT 100
