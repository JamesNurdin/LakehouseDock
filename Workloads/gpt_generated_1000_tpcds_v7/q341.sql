WITH filtered_date AS (
    SELECT d.d_date_sk, d.d_year, d.d_date
    FROM tpcds.date_dim d
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
),
joined AS (
    SELECT
        s.s_store_name,
        d.d_year,
        sr.sr_net_loss,
        cr.cr_net_loss,
        wr.wr_net_loss,
        r.r_reason_desc,
        ib.ib_upper_bound,
        cc.cc_name,
        w.w_warehouse_name,
        ws.web_manager,
        t.t_hour
    FROM filtered_date d
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE s.s_state = 'CA'
      AND ib.ib_upper_bound >= 80000
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
      AND t.t_hour BETWEEN 9 AND 17
      AND r.r_reason_desc LIKE '%damaged%'
      AND ws.web_manager = 'Marshall Conner'
)
SELECT
    s_store_name,
    d_year,
    SUM(sr_net_loss) AS store_net_loss,
    SUM(cr_net_loss) AS catalog_net_loss,
    SUM(wr_net_loss) AS web_net_loss,
    SUM(sr_net_loss + cr_net_loss + wr_net_loss) AS total_net_loss,
    DENSE_RANK() OVER (ORDER BY SUM(sr_net_loss + cr_net_loss + wr_net_loss) DESC) AS loss_rank,
    COUNT(DISTINCT sr_net_loss) AS return_rows,
    r_reason_desc,
    ib_upper_bound,
    cc_name,
    w_warehouse_name,
    web_manager
FROM joined
GROUP BY
    s_store_name,
    d_year,
    r_reason_desc,
    ib_upper_bound,
    cc_name,
    w_warehouse_name,
    web_manager
ORDER BY total_net_loss DESC
LIMIT 100
