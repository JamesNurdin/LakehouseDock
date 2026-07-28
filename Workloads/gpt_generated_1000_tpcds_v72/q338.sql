WITH base AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        sr.sr_return_amt,
        sr.sr_net_loss,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        i.i_category,
        i.i_brand,
        c.c_customer_id,
        ca.ca_state,
        d_sold.d_year,
        t_sold.t_hour,
        p.p_discount_active,
        ib.ib_lower_bound,
        r.r_reason_desc,
        w.w_warehouse_name,
        wp.wp_type,
        we.web_name
    FROM catalog_page cp
    JOIN catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON i.i_item_sk = cs.cs_item_sk
    JOIN customer c
        ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN customer_address ca
        ON ca.ca_address_sk = cs.cs_bill_addr_sk
    JOIN date_dim d_sold
        ON d_sold.d_date_sk = cs.cs_sold_date_sk
    JOIN time_dim t_sold
        ON t_sold.t_time_sk = cs.cs_sold_time_sk
    JOIN promotion p
        ON p.p_promo_sk = cs.cs_promo_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
    JOIN income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    LEFT JOIN reason r
        ON r.r_reason_sk = cr.cr_reason_sk
    JOIN warehouse w
        ON w.w_warehouse_sk = cs.cs_warehouse_sk
    -- store_sales and its dimensions
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d_ss
        ON d_ss.d_date_sk = ss.ss_sold_date_sk
    JOIN time_dim t_ss
        ON t_ss.t_time_sk = ss.ss_sold_time_sk
    -- store_returns and its dimensions
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d_sr
        ON d_sr.d_date_sk = sr.sr_returned_date_sk
    JOIN time_dim t_sr
        ON t_sr.t_time_sk = sr.sr_return_time_sk
    JOIN reason r_sr
        ON r_sr.r_reason_sk = sr.sr_reason_sk
    -- web_sales and its dimensions
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws
        ON d_ws.d_date_sk = ws.ws_sold_date_sk
    JOIN time_dim t_ws
        ON t_ws.t_time_sk = ws.ws_sold_time_sk
    JOIN web_page wp
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_site we
        ON we.web_site_sk = ws.ws_web_site_sk
    WHERE i.i_brand = 'Brand#45'
      AND ca.ca_state = 'CA'
      AND d_sold.d_year = 2001
      AND t_sold.t_hour BETWEEN 8 AND 17
      AND p.p_discount_active = 'Y'
      AND cp.cp_department = 'Electronics'
)
SELECT
    i_category,
    i_brand,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    AVG(ws_net_paid) AS avg_web_paid
FROM base
GROUP BY i_category, i_brand
HAVING SUM(cs_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
