WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        i.i_category,
        i.i_brand,
        d1.d_year,
        p.p_discount_active,
        r.r_reason_desc,
        ss.ss_ticket_number,
        sr.sr_returned_date_sk,
        wp.wp_web_page_id,
        cp.cp_department
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd1 ON cs.cs_bill_hdemo_sk = hd1.hd_demo_sk
    JOIN customer_address ca1 ON cs.cs_bill_addr_sk = ca1.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d3 ON ss.ss_sold_date_sk = d3.d_date_sk
    JOIN time_dim t3 ON ss.ss_sold_time_sk = t3.t_time_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d4 ON sr.sr_returned_date_sk = d4.d_date_sk
    JOIN time_dim t4 ON sr.sr_return_time_sk = t4.t_time_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d1.d_date_sk
    WHERE d1.d_year = 1999
      AND i.i_brand = 'Brand#13'
      AND p.p_discount_active = 'Y'
),
agg AS (
    SELECT
        i_category,
        d_year,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM base
    GROUP BY ROLLUP (i_category, d_year)
)
SELECT
    i_category,
    d_year,
    total_sales,
    total_profit,
    order_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS category_rank_year
FROM agg
ORDER BY d_year DESC, total_profit DESC
LIMIT 100
