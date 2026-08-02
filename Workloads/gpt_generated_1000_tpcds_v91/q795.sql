WITH ws_wr AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_site_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_refunded_cdemo_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_returning_cdemo_sk,
        wr.wr_returning_hdemo_sk
    FROM web_sales ws
    FULL OUTER JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
),
joined_base AS (
    SELECT
        ws_wr.ws_order_number,
        ws_wr.ws_net_paid,
        ws_wr.ws_net_profit,
        ws_wr.ws_ext_discount_amt,
        ws_wr.ws_quantity,
        ws_wr.ws_sold_date_sk,
        ws_wr.ws_sold_time_sk,
        ws_wr.ws_warehouse_sk,
        ws_wr.ws_web_site_sk,
        ws_wr.wr_return_amt,
        ws_wr.wr_return_quantity,
        ws_wr.wr_returned_date_sk,
        ws_wr.wr_returned_time_sk,
        ws_wr.wr_refunded_cdemo_sk,
        ws_wr.wr_refunded_hdemo_sk,
        ws_wr.wr_returning_cdemo_sk,
        ws_wr.wr_returning_hdemo_sk,
        d.d_year,
        t.t_hour,
        w.w_warehouse_name,
        w.w_gmt_offset,
        s.s_store_name,
        ws_site.web_site_id,
        ws_site.web_class,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM ws_wr
    LEFT JOIN date_dim d
        ON ws_wr.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON ws_wr.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN warehouse w
        ON ws_wr.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_site ws_site
        ON ws_wr.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
agg AS (
    SELECT
        d_year,
        w_warehouse_name,
        s_store_name,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(wr_return_amt) AS total_wr_return_amt,
        SUM(cr_return_amount) AS total_cr_return_amt,
        SUM(cr_net_loss) AS total_cr_net_loss,
        AVG(ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws_order_number) AS order_cnt
    FROM joined_base
    WHERE
        d_year = 2002
        AND t_hour BETWEEN 9 AND 18
        AND ws_net_paid BETWEEN 1000 AND 5000
        AND ws_ext_discount_amt > 0
        AND w_gmt_offset BETWEEN -5 AND 5
        AND web_class IS NOT NULL
    GROUP BY d_year, w_warehouse_name, s_store_name
)
SELECT
    a.d_year,
    a.w_warehouse_name,
    a.s_store_name,
    a.total_net_paid,
    a.total_net_profit,
    a.total_wr_return_amt,
    a.total_cr_return_amt,
    a.total_cr_net_loss,
    a.avg_discount,
    a.order_cnt,
    RANK() OVER (ORDER BY a.total_net_paid DESC) AS net_paid_rank,
    SUM(a.total_net_paid) OVER (PARTITION BY a.d_year) AS year_total_net_paid,
    AVG(a.total_net_profit) OVER (PARTITION BY a.w_warehouse_name) AS avg_warehouse_profit
FROM agg a
ORDER BY a.total_net_paid DESC
LIMIT 100
