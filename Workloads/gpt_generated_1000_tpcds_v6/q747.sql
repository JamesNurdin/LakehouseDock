WITH agg AS (
    SELECT
        d_ret.d_year,
        ws.web_class,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_inc_tax
    FROM web_returns wr
    JOIN date_dim d_ret
      ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN call_center cc
      ON cc.cc_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_cc_open
      ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN catalog_page cp
      ON cp.cp_start_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cp_end
      ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d_cp_end.d_date_sk
    JOIN date_dim d_ws_close
      ON ws.web_close_date_sk = d_ws_close.d_date_sk
    JOIN date_dim d_extra1
      ON cc.cc_closed_date_sk = d_extra1.d_date_sk
    JOIN date_dim d_extra2
      ON ws.web_open_date_sk = d_extra2.d_date_sk
    WHERE wr.wr_return_amt > (SELECT AVG(wr2.wr_return_amt) FROM web_returns wr2)
      AND d_ret.d_following_holiday = 'N'
    GROUP BY ROLLUP (d_ret.d_year, ws.web_class)
)
SELECT
    d_year,
    web_class,
    total_return_amt,
    return_cnt,
    avg_return_inc_tax,
    SUM(total_return_amt) OVER (PARTITION BY d_year) AS yearly_total,
    ROW_NUMBER() OVER (ORDER BY total_return_amt DESC) AS rn
FROM agg
ORDER BY d_year NULLS LAST, web_class NULLS LAST, total_return_amt DESC
LIMIT 100
