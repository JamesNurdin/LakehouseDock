WITH joined_data AS (
    SELECT
        cs.cs_ext_sales_price,
        ws.ws_net_paid_inc_ship_tax,
        wr.wr_net_loss,
        d.d_year,
        cp.cp_description,
        st.s_store_name,
        st.s_state,
        w.w_city
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer cust
        ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store st
        ON ss.ss_store_sk = st.s_store_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year = 2001
      AND cp.cp_description LIKE '%econom%'
      AND st.s_state = 'TX'
      AND w.w_city = 'Seattle'
      AND ws.ws_net_paid_inc_ship_tax > 1000
),
agg AS (
    SELECT
        s_store_name,
        d_year,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_net_paid_inc_ship_tax) AS total_web_sales,
        SUM(wr_net_loss) AS total_return_loss,
        CASE WHEN SUM(ws_net_paid_inc_ship_tax) > 0
            THEN SUM(cs_ext_sales_price) / SUM(ws_net_paid_inc_ship_tax)
            ELSE NULL
        END AS sales_ratio
    FROM joined_data
    GROUP BY ROLLUP (s_store_name, d_year)
)
SELECT
    s_store_name,
    d_year,
    total_catalog_sales,
    total_web_sales,
    total_return_loss,
    sales_ratio,
    RANK() OVER (PARTITION BY d_year ORDER BY total_web_sales DESC) AS sales_rank
FROM agg
ORDER BY d_year, sales_rank
LIMIT 100
