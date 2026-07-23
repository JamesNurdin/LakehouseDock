WITH base AS (
    SELECT
        cs.cs_net_paid_inc_ship_tax,
        cr.cr_return_amount,
        ws.ws_net_paid,
        wr.wr_return_amt,
        i.i_category,
        i.i_brand,
        c.c_customer_sk,
        cd.cd_gender,
        ca.ca_state,
        d.d_year,
        t.t_hour,
        s.s_store_name AS s_store_name,
        CASE WHEN cs.cs_net_paid_inc_ship_tax > 1000 THEN 'High' ELSE 'Low' END AS order_value_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN web_sales ws ON cs.cs_order_number = ws.ws_order_number
        AND ws.ws_item_sk = cs.cs_item_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk = 5
      AND t.t_hour BETWEEN 8 AND 12
      AND cs.cs_net_paid_inc_ship_tax > 500
      AND s.s_store_name LIKE '%Store%'
),
agg AS (
    SELECT
        i_category,
        i_brand,
        d_year,
        ca_state,
        cd_gender,
        s_store_name,
        order_value_category,
        COUNT(DISTINCT c_customer_sk) AS num_customers,
        SUM(cs_net_paid_inc_ship_tax) AS total_catalog_sales,
        SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_returns,
        SUM(COALESCE(ws_net_paid, 0)) AS total_web_sales,
        SUM(COALESCE(wr_return_amt, 0)) AS total_web_returns
    FROM base
    GROUP BY i_category, i_brand, d_year, ca_state, cd_gender, s_store_name, order_value_category
)
SELECT
    i_category,
    i_brand,
    d_year,
    ca_state,
    cd_gender,
    s_store_name,
    order_value_category,
    num_customers,
    total_catalog_sales,
    total_catalog_returns,
    total_web_sales,
    total_web_returns,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_catalog_sales DESC) AS sales_rank_by_category
FROM agg
ORDER BY total_catalog_sales DESC
LIMIT 100
