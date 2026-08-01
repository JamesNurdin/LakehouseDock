WITH sales_details AS (
    SELECT
        ss.ss_ticket_number,
        d_ss.d_year AS sales_year,
        w.w_state,
        p.p_promo_name,
        ib.ib_upper_bound,
        ca_ss.ca_country,
        c.c_preferred_cust_flag,
        t_ss.t_hour,
        ss.ss_ext_sales_price AS ss_sales,
        cs.cs_ext_sales_price AS cs_sales,
        COALESCE(cr.cr_return_amount, 0) AS return_amount,
        inv.inv_quantity_on_hand,
        ws.web_name,
        wp.wp_type,
        r.r_reason_desc,
        cc.cc_name
    FROM store_sales ss
    JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN income_band ib
        ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ss.d_date_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_ss.d_year = 2002
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND ib.ib_upper_bound >= 100000
      AND c.c_preferred_cust_flag = 'Y'
),
promo_agg AS (
    SELECT
        sales_year,
        p_promo_name,
        SUM(ss_sales + cs_sales) AS total_sales,
        SUM(return_amount) AS total_returns,
        SUM(ss_sales + cs_sales - return_amount) AS net_sales,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(*) AS transaction_cnt
    FROM sales_details
    GROUP BY sales_year, p_promo_name
    HAVING SUM(ss_sales + cs_sales) > 500000
)
SELECT
    sales_year,
    p_promo_name,
    total_sales,
    total_returns,
    net_sales,
    total_inventory,
    transaction_cnt
FROM promo_agg
WHERE total_sales > (SELECT AVG(total_sales) FROM promo_agg)
ORDER BY net_sales DESC
LIMIT 100
