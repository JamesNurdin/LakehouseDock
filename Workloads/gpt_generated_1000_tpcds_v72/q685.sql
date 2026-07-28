WITH joined_data AS (
    SELECT
        s.s_store_name,
        d.d_year,
        cs.cs_net_paid,
        sr.sr_net_loss,
        i.i_category,
        i.i_brand,
        cp.cp_department,
        w.w_warehouse_name,
        r.r_reason_desc,
        ib.ib_lower_bound,
        t_sales.t_hour,
        wp.wp_url,
        wr.wr_return_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t_sales
        ON cs.cs_sold_time_sk = t_sales.t_time_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    /* Store‑return side – joined through the same date dimension */
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    /* Web‑return side – also joined through the same date dimension */
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN time_dim t_return
        ON wr.wr_returned_time_sk = t_return.t_time_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_category = 'Electronics'
      AND ib.ib_lower_bound >= 100000
)
SELECT
    s_store_name,
    d_year,
    SUM(cs_net_paid)          AS total_sales,
    SUM(sr_net_loss)          AS total_returns,
    (SUM(cs_net_paid) - SUM(sr_net_loss)) AS net_margin,
    RANK() OVER (PARTITION BY d_year ORDER BY (SUM(cs_net_paid) - SUM(sr_net_loss)) DESC) AS store_rank
FROM joined_data
GROUP BY s_store_name, d_year
ORDER BY net_margin DESC
LIMIT 10
