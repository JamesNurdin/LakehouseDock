WITH base AS (
    SELECT
        cp.cp_department AS department,
        d_sold.d_year AS year,
        cs.cs_ext_sales_price AS sales,
        cs.cs_ext_sales_price + COALESCE(cr.cr_return_amount, 0) AS sales_plus_returns,
        c.c_customer_sk,
        ca.ca_zip,
        ib.ib_upper_bound,
        p.p_discount_active,
        cd.cd_gender,
        sr.sr_net_loss,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand,
        ARRAY[cs.cs_ext_sales_price, COALESCE(cr.cr_return_amount, 0)] AS metric_vals
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND cp.cp_type = 'Catalog'
      AND ca.ca_zip LIKE '75%'
      AND ib.ib_upper_bound <= 150000
      AND p.p_discount_active = 'Y'
      AND cd.cd_gender = 'M'
      AND sr.sr_net_loss IS NOT NULL
      AND wr.wr_return_amt > 0
      AND inv.inv_quantity_on_hand > 0
)
SELECT
    b.department,
    b.year,
    SUM(b.sales) AS total_sales,
    ROW_NUMBER() OVER (ORDER BY SUM(b.sales) DESC) AS global_row_num,
    ROW_NUMBER() OVER (PARTITION BY b.department ORDER BY SUM(b.sales) DESC) AS dept_rank,
    (SELECT SUM(wr2.wr_net_loss)
       FROM web_returns wr2
       WHERE wr2.wr_refunded_customer_sk = b.c_customer_sk) AS cust_web_return_loss,
    metric_val
FROM (
    SELECT
        department,
        year,
        sales,
        c_customer_sk,
        metric_vals
    FROM base
) b
CROSS JOIN UNNEST(b.metric_vals) AS t(metric_val)
GROUP BY b.department, b.year, b.c_customer_sk, metric_val
HAVING SUM(b.sales) > 500
ORDER BY total_sales DESC
LIMIT 100
