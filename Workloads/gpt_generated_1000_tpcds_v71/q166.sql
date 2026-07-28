WITH base AS (
    SELECT
        d.d_year AS d_year,
        sm.sm_type AS sm_type,
        r.r_reason_desc AS r_reason_desc,
        c.c_last_name AS c_last_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(sr.sr_return_amt_inc_tax) AS total_store_return,
        SUM(sr.sr_net_loss) AS total_store_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_return,
        SUM(wr.wr_net_loss) AS total_web_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc LIKE '%color%'
      AND c.c_last_name IN ('Sharp', 'Moran')
      AND cs.cs_ext_sales_price > 100
    GROUP BY ROLLUP (d.d_year, sm.sm_type, r.r_reason_desc, c.c_last_name)
)
SELECT
    d_year,
    sm_type,
    r_reason_desc,
    c_last_name,
    total_sales,
    total_profit,
    total_store_loss,
    total_web_loss,
    (total_profit - total_store_loss - total_web_loss) / NULLIF(total_sales, 0) * 100 AS profit_margin_percent
FROM base
WHERE (total_profit - total_store_loss - total_web_loss) / NULLIF(total_sales, 0) * 100 > 5
ORDER BY d_year, sm_type, r_reason_desc, c_last_name
LIMIT 100
