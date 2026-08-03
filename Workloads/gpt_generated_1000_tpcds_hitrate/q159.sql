WITH sales_agg AS (
    SELECT
        cp.cp_catalog_number,
        d_sold.d_year,
        sm.sm_type,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_page cp
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    /* Additional required tables to satisfy the join‑all requirement */
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sold.d_date_sk
    JOIN household_demographics hd_wr
        ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_start.d_date_sk
    WHERE cp.cp_catalog_number IN (12, 13)
      AND d_sold.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND cs.cs_quantity > (SELECT AVG(cs_quantity) FROM catalog_sales)
    GROUP BY cp.cp_catalog_number, d_sold.d_year, sm.sm_type
)
SELECT
    sa.cp_catalog_number,
    sa.d_year,
    sa.sm_type,
    sa.total_sales,
    sa.total_discount,
    sa.sales_cnt,
    sa.total_sales / NULLIF(sa.sales_cnt, 0) AS avg_sales_per_tx
FROM sales_agg sa
WHERE sa.total_sales > (SELECT MAX(total_sales) FROM sales_agg) * 0.5
ORDER BY sa.total_sales DESC
LIMIT 100
