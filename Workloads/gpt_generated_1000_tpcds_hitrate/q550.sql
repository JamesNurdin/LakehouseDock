WITH sr_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt) AS store_ret_amt,
        SUM(sr.sr_fee) AS store_fee,
        COUNT(*) AS store_ret_cnt
    FROM store_returns sr
    WHERE sr.sr_return_amt > 0
    GROUP BY sr.sr_item_sk, sr.sr_store_sk, sr.sr_returned_date_sk
)
SELECT
    d.d_year,
    i.i_category,
    s.s_store_name,
    SUM(sr_agg.store_ret_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(sr_agg.store_ret_amt) + SUM(wr.wr_return_amt) AS total_return_amt,
    CASE WHEN SUM(sr_agg.store_ret_amt) > SUM(wr.wr_return_amt)
         THEN 'Store Higher'
         ELSE 'Web Higher'
    END AS higher_source,
    LAG(SUM(sr_agg.store_ret_amt) + SUM(wr.wr_return_amt)) OVER (PARTITION BY i.i_category ORDER BY d.d_year) AS prev_year_total,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY d.d_year DESC) AS rn
FROM sr_agg
JOIN item i
  ON sr_agg.sr_item_sk = i.i_item_sk
JOIN store s
  ON sr_agg.sr_store_sk = s.s_store_sk
JOIN date_dim d
  ON sr_agg.sr_returned_date_sk = d.d_date_sk
-- join the full store_returns row to get reason, customer, address, demographics, time, etc.
JOIN store_returns sr
  ON sr.sr_item_sk = sr_agg.sr_item_sk
 AND sr.sr_store_sk = sr_agg.sr_store_sk
 AND sr.sr_returned_date_sk = sr_agg.sr_returned_date_sk
JOIN reason r_store
  ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN time_dim t
  ON sr.sr_return_time_sk = t.t_time_sk
-- web returns side
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
 AND wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r_web
  ON wr.wr_reason_sk = r_web.r_reason_sk
JOIN customer c_refunded
  ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning
  ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer_demographics cd_refunded
  ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded
  ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer_address ca_refunded
  ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY ROLLUP (d.d_year, i.i_category, s.s_store_name)
HAVING SUM(sr_agg.store_ret_amt) > 0
ORDER BY d.d_year NULLS LAST, i.i_category, s.s_store_name
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
