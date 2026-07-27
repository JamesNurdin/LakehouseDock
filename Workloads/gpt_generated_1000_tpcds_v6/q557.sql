WITH ss_agg AS (
    SELECT
        ss_customer_sk,
        ss_sold_date_sk,
        ss_hdemo_sk,
        SUM(ss_net_paid_inc_tax) AS total_sales,
        SUM(ss_ext_sales_price) AS total_ext_sales
    FROM store_sales
    WHERE ss_net_paid_inc_tax > 0
    GROUP BY ss_customer_sk, ss_sold_date_sk, ss_hdemo_sk
),
cr_agg AS (
    SELECT
        cr_refunded_customer_sk AS customer_sk,
        cr_returned_date_sk AS returned_date_sk,
        SUM(cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_quantity > 0
    GROUP BY cr_refunded_customer_sk, cr_returned_date_sk
)
SELECT
    c.c_customer_id,
    d_sales.d_year,
    SUM(ss_agg.total_sales) AS yearly_sales,
    COALESCE(SUM(cr_agg.total_return_loss), 0) AS yearly_return_loss,
    (SUM(ss_agg.total_sales) - COALESCE(SUM(cr_agg.total_return_loss), 0)) AS net_revenue,
    CASE
        WHEN ib.ib_lower_bound >= 80000 THEN 'High Income'
        WHEN ib.ib_lower_bound >= 50000 THEN 'Medium Income'
        ELSE 'Low Income'
    END AS income_category,
    ws.web_name,
    cp.cp_department,
    r.r_reason_desc,
    ROW_NUMBER() OVER (PARTITION BY d_sales.d_year ORDER BY (SUM(ss_agg.total_sales) - COALESCE(SUM(cr_agg.total_return_loss), 0)) DESC) AS sales_rank
FROM ss_agg
JOIN date_dim d_sales ON ss_agg.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer c ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN cr_agg ON cr_agg.customer_sk = c.c_customer_sk
    AND cr_agg.returned_date_sk = d_sales.d_date_sk
LEFT JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    AND cr.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year BETWEEN 1999 AND 2001
  AND c.c_preferred_cust_flag = 'Y'
  AND ib.ib_upper_bound IS NOT NULL
GROUP BY
    c.c_customer_id,
    d_sales.d_year,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ws.web_name,
    cp.cp_department,
    r.r_reason_desc
ORDER BY d_sales.d_year DESC, net_revenue DESC
LIMIT 100
