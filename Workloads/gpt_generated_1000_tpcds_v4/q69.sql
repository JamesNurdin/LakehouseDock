WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        ca.ca_state,
        wp.wp_type,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'CA'
      AND ib.ib_upper_bound >= 80000
      AND sm.sm_type = 'AIR'
      AND wp.wp_image_count > 3
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_brand,
             p.p_promo_name, sm.sm_type, w.w_warehouse_name,
             ca.ca_state, wp.wp_type
),
store_sales_agg AS (
    SELECT
        d.d_year AS ss_year,
        i.i_category AS ss_category,
        SUM(ss.ss_ext_sales_price) AS ss_total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS ss_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_year, i.i_category
),
returns_agg AS (
    SELECT
        d.d_year AS ret_year,
        r.r_reason_desc,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY d.d_year, r.r_reason_desc
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.i_brand,
    s.p_promo_name,
    s.ship_mode_type,
    s.w_warehouse_name,
    s.ca_state,
    s.wp_type,
    s.orders,
    s.total_sales,
    s.total_profit,
    s.avg_quantity,
    ss.ss_total_sales,
    ss.ss_transactions,
    r.total_return_amount,
    r.return_cnt
FROM sales_agg s
LEFT JOIN store_sales_agg ss
    ON s.d_year = ss.ss_year
   AND s.i_category = ss.ss_category
LEFT JOIN returns_agg r
    ON s.d_year = r.ret_year
ORDER BY s.total_sales DESC
LIMIT 100
