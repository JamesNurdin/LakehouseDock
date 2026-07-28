WITH joined AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id,
        i.i_brand,
        d.d_year,
        cs.cs_net_paid,
        cs.cs_quantity,
        ws.ws_net_paid,
        r.r_reason_desc,
        w.w_state,
        cp.cp_department,
        s.s_store_name
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON cs.cs_order_number = ws.ws_order_number
       AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND cp.cp_department = 'Sports'
      AND r.r_reason_desc LIKE '%price%'
      AND w.w_state = 'CA'
)
SELECT DISTINCT
    c_customer_id,
    c_first_name,
    c_last_name,
    i_item_id,
    i_brand,
    d_year,
    SUM(cs_net_paid + ws_net_paid) AS total_net_paid,
    SUM(cs_quantity) AS total_quantity,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(cs_net_paid + ws_net_paid) DESC) AS yearly_sales_rank,
    SUM(SUM(cs_net_paid + ws_net_paid)) OVER (PARTITION BY c_customer_id ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_by_customer
FROM joined
GROUP BY
    c_customer_id,
    c_first_name,
    c_last_name,
    i_item_id,
    i_brand,
    d_year
ORDER BY total_net_paid DESC
LIMIT 100
