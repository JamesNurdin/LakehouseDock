WITH cat_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        d.d_year,
        t.t_hour,
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        cd.cd_demo_sk,
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_address_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
)
SELECT
    cb.d_year,
    s.s_state,
    cb.c_preferred_cust_flag,
    r.r_reason_desc,
    COUNT(DISTINCT cb.c_customer_sk) AS uniq_customers,
    SUM(cb.cs_net_paid) AS total_catalog_sales,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    AVG(cb.ib_upper_bound - cb.ib_lower_bound) AS avg_income_range
FROM cat_base cb
JOIN store_sales ss
    ON ss.ss_sold_date_sk = cb.cs_sold_date_sk
   AND ss.ss_sold_time_sk = cb.cs_sold_time_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = cb.cs_item_sk
   AND cr.cr_order_number = cb.cs_order_number
   AND cr.cr_refunded_customer_sk = cb.c_customer_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = cb.c_customer_sk
   AND wr.wr_item_sk = cb.cs_item_sk
   AND wr.wr_order_number = cb.cs_order_number
JOIN web_site ws
    ON ws.web_open_date_sk = cb.cs_sold_date_sk
WHERE
    cb.d_year = 2001
    AND cb.c_preferred_cust_flag = 'Y'
    AND cb.ib_lower_bound >= 80000
    AND s.s_state = 'CA'
GROUP BY
    cb.d_year,
    s.s_state,
    cb.c_preferred_cust_flag,
    r.r_reason_desc
HAVING
    SUM(cb.cs_net_paid) > 10000
UNION ALL
SELECT
    cb.d_year,
    s.s_state,
    cb.c_preferred_cust_flag,
    r.r_reason_desc,
    COUNT(DISTINCT cb.c_customer_sk) AS uniq_customers,
    SUM(cb.cs_net_paid) AS total_catalog_sales,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    AVG(cb.ib_upper_bound - cb.ib_lower_bound) AS avg_income_range
FROM cat_base cb
JOIN store_sales ss
    ON ss.ss_sold_date_sk = cb.cs_sold_date_sk
   AND ss.ss_sold_time_sk = cb.cs_sold_time_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = cb.cs_item_sk
   AND cr.cr_order_number = cb.cs_order_number
   AND cr.cr_refunded_customer_sk = cb.c_customer_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = cb.c_customer_sk
   AND wr.wr_item_sk = cb.cs_item_sk
   AND wr.wr_order_number = cb.cs_order_number
JOIN web_site ws
    ON ws.web_open_date_sk = cb.cs_sold_date_sk
WHERE
    cb.d_year = 2002
    AND cb.c_preferred_cust_flag = 'N'
    AND cb.ib_upper_bound <= 150000
    AND s.s_state = 'TX'
GROUP BY
    cb.d_year,
    s.s_state,
    cb.c_preferred_cust_flag,
    r.r_reason_desc
HAVING
    SUM(cb.cs_net_paid) > 5000
LIMIT 100
