WITH agg_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_store_sk,
        ss_promo_sk,
        SUM(ss_net_paid) AS sales_amount,
        SUM(ss_net_profit) AS profit_amount
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_sold_time_sk, ss_item_sk, ss_store_sk, ss_promo_sk
)
SELECT
    ROW_NUMBER() OVER (ORDER BY COALESCE(d_sold.d_year, 0) DESC, s.s_store_name) AS row_num,
    s.s_store_name,
    d_sold.d_year,
    i1.i_category,
    SUM(agg.sales_amount)                 AS total_sales,
    SUM(cr.cr_return_amount)              AS total_catalog_return,
    SUM(wr.wr_return_amt)                 AS total_web_return
FROM agg_sales agg
JOIN date_dim d_sold
  ON agg.ss_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON agg.ss_sold_time_sk = t_sold.t_time_sk
JOIN item i1
  ON agg.ss_item_sk = i1.i_item_sk
JOIN store s
  ON agg.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON agg.ss_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr
  ON i1.i_item_sk = cr.cr_item_sk
 AND d_sold.d_date_sk = cr.cr_returned_date_sk
LEFT JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
LEFT JOIN time_dim t_ret
  ON cr.cr_returned_time_sk = t_ret.t_time_sk
LEFT JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_returns wr
  ON i1.i_item_sk = wr.wr_item_sk
 AND d_sold.d_date_sk = wr.wr_returned_date_sk
LEFT JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN time_dim t_wr
  ON wr.wr_returned_time_sk = t_wr.t_time_sk
GROUP BY GROUPING SETS (
    (s.s_store_name, d_sold.d_year, i1.i_category),
    (s.s_store_name, d_sold.d_year),
    (i1.i_category),
    ()
)
ORDER BY row_num
LIMIT 100
