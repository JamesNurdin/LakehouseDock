WITH
  sales_sample AS (
    SELECT ss_hdemo_sk,
           ss_sold_date_sk,
           ss_net_paid_inc_tax,
           ss_ext_sales_price
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_net_paid_inc_tax > 500
  ),
  filtered_sales AS (
    SELECT ss_hdemo_sk,
           ss_sold_date_sk,
           ss_net_paid_inc_tax,
           ss_ext_sales_price
    FROM sales_sample
    WHERE ss_sold_date_sk IN (
      SELECT d_date_sk
      FROM date_dim
      WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-03-31'
    )
  ),
  demo_filtered AS (
    SELECT hd_demo_sk,
           hd_buy_potential,
           hd_income_band_sk
    FROM household_demographics
    WHERE regexp_like(hd_buy_potential, '^([A-Z]{2,})$')
  ),
  reason_filtered AS (
    SELECT r_reason_sk,
           regexp_extract(r_reason_desc, '(\\w+)\\s+\\w+$', 1) AS last_word,
           r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%store%'
  ),
  returns_hd AS (
    SELECT wr_refunded_hdemo_sk AS hd_demo_sk,
           wr_returned_date_sk
    FROM web_returns
    WHERE wr_returned_date_sk IN (
      SELECT d_date_sk
      FROM date_dim
      WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-03-31'
    )
  ),
  common_hd AS (
    SELECT ss_hdemo_sk AS hd_demo_sk
    FROM filtered_sales
    INTERSECT
    SELECT hd_demo_sk
    FROM returns_hd
  ),
  sales_without_returns AS (
    SELECT ss_hdemo_sk AS hd_demo_sk
    FROM filtered_sales
    EXCEPT
    SELECT hd_demo_sk
    FROM returns_hd
  ),
  sales_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           demo.hd_buy_potential,
           SUM(fs.ss_net_paid_inc_tax) AS total_net_paid,
           COUNT(*) AS sales_cnt
    FROM filtered_sales fs
    JOIN date_dim d ON fs.ss_sold_date_sk = d.d_date_sk
    JOIN demo_filtered demo ON fs.ss_hdemo_sk = demo.hd_demo_sk
    GROUP BY d.d_year, d.d_month_seq, demo.hd_buy_potential
  ),
  returns_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           demo.hd_buy_potential,
           SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
           COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN demo_filtered demo ON wr.wr_refunded_hdemo_sk = demo.hd_demo_sk
    JOIN reason_filtered r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-03-31'
    GROUP BY d.d_year, d.d_month_seq, demo.hd_buy_potential
  ),
  union_agg AS (
    SELECT year_month,
           buy_potential,
           metric,
           cnt
    FROM (
      SELECT CAST(d_year AS VARCHAR) || '-' || LPAD(CAST(d_month_seq AS VARCHAR), 2, '0') AS year_month,
             hd_buy_potential AS buy_potential,
             total_net_paid AS metric,
             sales_cnt AS cnt
      FROM sales_agg
      UNION DISTINCT
      SELECT CAST(d_year AS VARCHAR) || '-' || LPAD(CAST(d_month_seq AS VARCHAR), 2, '0') AS year_month,
             hd_buy_potential AS buy_potential,
             total_return_amt AS metric,
             returns_cnt AS cnt
      FROM returns_agg
    )
  )
SELECT ua.year_month,
       ua.buy_potential,
       SUM(ua.metric) AS total_metric,
       SUM(ua.cnt) AS total_cnt,
       (SELECT COUNT(*) FROM common_hd) AS common_demo_count,
       (SELECT COUNT(*) FROM sales_without_returns) AS sales_without_return_demo_count
FROM union_agg ua
GROUP BY ua.year_month, ua.buy_potential
ORDER BY total_metric DESC
LIMIT 100
