WITH base AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        ca.ca_state,
        ca.ca_city,
        cp.cp_department,
        cp.cp_catalog_page_number,
        r.r_reason_desc,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_item_sk,
        cs.cs_sold_time_sk
    FROM date_dim d
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = cs.cs_item_sk
    LEFT JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND cp.cp_department = 'Sports'
      AND (r.r_reason_desc = 'Damaged' OR r.r_reason_desc IS NULL)
)
SELECT
    d_year,
    ca_state,
    cp_department,
    SUM(cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    AVG(cs_net_profit) AS avg_profit,
    CASE WHEN SUM(cs_quantity) > 1000 THEN 'High Volume' ELSE 'Low Volume' END AS volume_category,
    ROW_NUMBER() OVER (ORDER BY SUM(cs_ext_sales_price) DESC) AS rn,
    RANK() OVER (PARTITION BY ca_state ORDER BY SUM(cs_ext_sales_price) DESC) AS state_sales_rank,
    (SELECT MAX(d_date) FROM date_dim WHERE d_year = 2001) AS max_date_2001
FROM base
WHERE EXISTS (
    SELECT 1 FROM catalog_returns cr2
    WHERE cr2.cr_order_number = base.cs_order_number
      AND cr2.cr_return_quantity > 0
)
GROUP BY d_year, ca_state, cp_department
ORDER BY total_sales DESC
LIMIT 100
