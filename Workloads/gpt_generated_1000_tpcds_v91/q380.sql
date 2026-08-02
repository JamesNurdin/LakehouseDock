WITH base AS (
    SELECT
        cc.cc_division_name AS division,
        d_date.d_year AS year,
        cc.cc_tax_percentage AS tax_pct,
        p.p_discount_active AS promo_active,
        SUM(cs.cs_net_profit) AS sum_cs,
        SUM(ss.ss_net_profit) AS sum_ss,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS sum_cr_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS sum_wr_loss,
        (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) - SUM(COALESCE(cr.cr_net_loss, 0)) - SUM(COALESCE(wr.wr_net_loss, 0))) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d_date ON cs.cs_sold_date_sk = d_date.d_date_sk
    JOIN time_dim t_time ON cs.cs_sold_time_sk = t_time.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = cs.cs_order_number
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d_date.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d_date.d_date_sk AND ss.ss_sold_time_sk = t_time.t_time_sk
    GROUP BY cc.cc_division_name, d_date.d_year, cc.cc_tax_percentage, p.p_discount_active
)
SELECT
    division,
    year,
    total_net_profit,
    CASE WHEN total_net_profit >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT division, year, total_net_profit FROM base
    WHERE year = 1998 AND tax_pct > 0.05 AND promo_active = 'Y'
    UNION DISTINCT
    SELECT division, year, total_net_profit FROM base
    WHERE year = 1998 AND tax_pct > 0.06 AND promo_active = 'Y'
) AS combined
ORDER BY profit_rank, division
