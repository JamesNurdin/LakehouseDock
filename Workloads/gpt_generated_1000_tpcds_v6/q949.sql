WITH sales_summary AS (
    SELECT
        c.c_customer_id,
        COALESCE(dcs.d_year, dss.d_year, dws.d_year) AS year,
        SUM(COALESCE(cs.cs_net_paid, 0)) +
        SUM(COALESCE(ss.ss_net_paid, 0)) +
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_net_paid,
        SUM(COALESCE(cr.cr_return_amount, 0)) +
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount
    FROM customer c
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim dcs
        ON cs.cs_sold_date_sk = dcs.d_date_sk
    LEFT JOIN time_dim tcs
        ON cs.cs_sold_time_sk = tcs.t_time_sk
    LEFT JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim dss
        ON ss.ss_sold_date_sk = dss.d_date_sk
    LEFT JOIN time_dim tss
        ON ss.ss_sold_time_sk = tss.t_time_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim dws
        ON ws.ws_sold_date_sk = dws.d_date_sk
    LEFT JOIN time_dim tws
        ON ws.ws_sold_time_sk = tws.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = dcs.d_date_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE dcs.d_year = 2001
      AND ib.ib_upper_bound > 50000
      AND w.w_state = 'CA'
    GROUP BY c.c_customer_id,
        COALESCE(dcs.d_year, dss.d_year, dws.d_year)
)
SELECT
    c_customer_id,
    year,
    total_net_paid,
    RANK() OVER (PARTITION BY year ORDER BY total_net_paid DESC) AS revenue_rank,
    CASE WHEN total_return_amount > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_flag
FROM sales_summary
ORDER BY year, revenue_rank
LIMIT 100
