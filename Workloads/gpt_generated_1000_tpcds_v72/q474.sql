WITH data AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        i.i_brand,
        i.i_category,
        s.s_store_name,
        s.s_state,
        d_sold.d_year,
        d_sold.d_fy_week_seq,
        t_sold.t_sub_shift,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        p.p_discount_active,
        r.r_reason_desc,
        sm.sm_type,
        w.w_warehouse_name,
        wp.wp_type,
        ws2.web_name,
        cp.cp_type
    FROM store_sales ss
    JOIN date_dim d_sold
      ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d_return
      ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return
      ON sr.sr_return_time_sk = t_return.t_time_sk
    LEFT JOIN reason r
      ON r.r_reason_sk = sr.sr_reason_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_item_sk = ss.ss_item_sk
    LEFT JOIN catalog_page cp
      ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    LEFT JOIN ship_mode sm
      ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    LEFT JOIN warehouse w
      ON w.w_warehouse_sk = cr.cr_warehouse_sk
    LEFT JOIN web_sales ws
      ON ws.ws_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d_ws_sold
      ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    LEFT JOIN time_dim t_ws_sold
      ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    LEFT JOIN web_page wp
      ON wp.wp_web_page_sk = ws.ws_web_page_sk
    LEFT JOIN web_site ws2
      ON ws2.web_site_sk = ws.ws_web_site_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN date_dim d_wr_return
      ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
    LEFT JOIN time_dim t_wr_return
      ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
    LEFT JOIN reason r_wr
      ON r_wr.r_reason_sk = wr.wr_reason_sk
    WHERE d_sold.d_year = 2001
      AND t_sold.t_sub_shift = 'evening'
      AND i.i_brand = 'BrandX'
      AND s.s_state = 'TX'
      AND p.p_discount_active = 'Y'
      AND ib.ib_upper_bound > 50000
),
agg AS (
    SELECT
        d_year,
        s_store_name,
        i_brand,
        i_category,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
        AVG(ws_ext_sales_price) AS avg_web_sales,
        -- scalar subquery returning the maximum upper bound for income bands above a threshold
        (SELECT MAX(ib_sub.ib_upper_bound) FROM income_band ib_sub WHERE ib_sub.ib_lower_bound > 40000) AS max_income_upper
    FROM data
    GROUP BY d_year, s_store_name, i_brand, i_category
    HAVING SUM(ss_ext_sales_price) > 100000
)
SELECT
    d_year,
    s_store_name,
    i_brand,
    i_category,
    total_sales,
    total_profit,
    distinct_tickets,
    avg_web_sales,
    max_income_upper,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
