SELECT
  COALESCE(s.cs_profit, 0) + COALESCE(s2.ss_profit, 0) + COALESCE(s3.ws_profit, 0) - COALESCE(r.cr_ret_amt, 0) - COALESCE(r.sr_ret_amt, 0) - COALESCE(r.wr_ret_amt, 0) AS net_profit,
  COALESCE(s.cs_sales, 0) + COALESCE(s2.ss_sales, 0) + COALESCE(s3.ws_sales, 0) AS total_sales,
  COALESCE(s.d_year, s2.d_year, s3.d_year) AS d_year,
  COALESCE(s.d_month_seq, s2.d_month_seq, s3.d_month_seq) AS d_month_seq,
  COALESCE(s.i_category, s2.i_category, s3.i_category) AS i_category,
  RANK() OVER (
    PARTITION BY COALESCE(s.i_category, s2.i_category, s3.i_category)
    ORDER BY (COALESCE(s.cs_profit, 0) + COALESCE(s2.ss_profit, 0) + COALESCE(s3.ws_profit, 0) - COALESCE(r.cr_ret_amt, 0) - COALESCE(r.sr_ret_amt, 0) - COALESCE(r.wr_ret_amt, 0)) DESC
  ) AS profit_rank,
  AVG(
    COALESCE(s.cs_profit, 0) + COALESCE(s2.ss_profit, 0) + COALESCE(s3.ws_profit, 0) - COALESCE(r.cr_ret_amt, 0) - COALESCE(r.sr_ret_amt, 0) - COALESCE(r.wr_ret_amt, 0)
  ) OVER (
    PARTITION BY COALESCE(s.i_category, s2.i_category, s3.i_category)
    ORDER BY COALESCE(s.d_year, s2.d_year, s3.d_year), COALESCE(s.d_month_seq, s2.d_month_seq, s3.d_month_seq)
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS moving_avg_3_months
FROM
  (
    SELECT
      i.i_category,
      d.d_year,
      d.d_month_seq,
      SUM(cs.cs_net_profit) AS cs_profit,
      SUM(cs.cs_ext_sales_price) AS cs_sales
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2003
    GROUP BY i.i_category, d.d_year, d.d_month_seq
  ) s
FULL OUTER JOIN
  (
    SELECT
      i.i_category,
      d.d_year,
      d.d_month_seq,
      SUM(ss.ss_net_profit) AS ss_profit,
      SUM(ss.ss_ext_sales_price) AS ss_sales
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2003
    GROUP BY i.i_category, d.d_year, d.d_month_seq
  ) s2
  ON s.i_category = s2.i_category
 AND s.d_year = s2.d_year
 AND s.d_month_seq = s2.d_month_seq
FULL OUTER JOIN
  (
    SELECT
      i.i_category,
      d.d_year,
      d.d_month_seq,
      SUM(ws.ws_net_profit) AS ws_profit,
      SUM(ws.ws_ext_sales_price) AS ws_sales
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2003
    GROUP BY i.i_category, d.d_year, d.d_month_seq
  ) s3
  ON COALESCE(s.i_category, s2.i_category) = s3.i_category
 AND COALESCE(s.d_year, s2.d_year) = s3.d_year
 AND COALESCE(s.d_month_seq, s2.d_month_seq) = s3.d_month_seq
LEFT JOIN
  (
    SELECT
      i_category,
      d_year,
      d_month_seq,
      SUM(cr_ret_amt) AS cr_ret_amt,
      SUM(sr_ret_amt) AS sr_ret_amt,
      SUM(wr_ret_amt) AS wr_ret_amt
    FROM (
      SELECT
        cr.cr_return_amount AS cr_ret_amt,
        CAST(NULL AS DECIMAL(7,2)) AS sr_ret_amt,
        CAST(NULL AS DECIMAL(7,2)) AS wr_ret_amt,
        i.i_category AS i_category,
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq
      FROM catalog_returns cr
      JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
      JOIN item i ON cs.cs_item_sk = i.i_item_sk
      JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
      WHERE d.d_year BETWEEN 2001 AND 2003
      UNION ALL
      SELECT
        CAST(NULL AS DECIMAL(7,2)) AS cr_ret_amt,
        sr.sr_return_amt AS sr_ret_amt,
        CAST(NULL AS DECIMAL(7,2)) AS wr_ret_amt,
        i.i_category,
        d.d_year,
        d.d_month_seq
      FROM store_returns sr
      JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
      JOIN item i ON ss.ss_item_sk = i.i_item_sk
      JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
      WHERE d.d_year BETWEEN 2001 AND 2003
      UNION ALL
      SELECT
        CAST(NULL AS DECIMAL(7,2)) AS cr_ret_amt,
        CAST(NULL AS DECIMAL(7,2)) AS sr_ret_amt,
        wr.wr_return_amt AS wr_ret_amt,
        i.i_category,
        d.d_year,
        d.d_month_seq
      FROM web_returns wr
      JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
      JOIN item i ON ws.ws_item_sk = i.i_item_sk
      JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
      WHERE d.d_year BETWEEN 2001 AND 2003
    ) t
    GROUP BY i_category, d_year, d_month_seq
  ) r
ON COALESCE(s.i_category, s2.i_category, s3.i_category) = r.i_category
 AND COALESCE(s.d_year, s2.d_year, s3.d_year) = r.d_year
 AND COALESCE(s.d_month_seq, s2.d_month_seq, s3.d_month_seq) = r.d_month_seq
ORDER BY net_profit DESC
LIMIT 100
