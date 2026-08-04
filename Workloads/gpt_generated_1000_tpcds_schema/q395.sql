WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cp.cp_type,
        i.i_container,
        i.i_current_price,
        cc.cc_name,
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        wsite.web_name        AS web_site_name,
        wsite.web_state,
        wp.wp_link_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd_bill.hd_income_band_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        ARRAY[cs.cs_quantity, cs.cs_ext_sales_price] AS qty_price_arr
    FROM catalog_sales cs
    JOIN date_dim d                         ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp                    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc                     ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i                             ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd_bill    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill           ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN store s                            ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws                       ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp                        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite                     ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN catalog_returns cr                ON cr.cr_order_number = cs.cs_order_number
    JOIN income_band ib                     ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND i.i_container = 'Unknown'
      AND wsite.web_state = 'CA'
      AND cp.cp_type = 'monthly'
)
SELECT
    b.s_store_name,
    b.web_site_name,
    b.d_month_seq,
    SUM(b.cs_net_paid)           AS total_net_paid,
    SUM(b.cr_return_amount)      AS total_return_amount,
    AVG(b.cs_ext_discount_amt)   AS avg_discount,
    COUNT(DISTINCT b.cs_order_number) AS order_count,
    SUM(t.val)                   AS sum_qty_price_vals,
    (
        SELECT COUNT(*)
        FROM (SELECT cs_order_number FROM catalog_sales) AS cs_orders
        EXCEPT
        SELECT cr_order_number FROM catalog_returns
    ) AS orders_without_returns
FROM base b
CROSS JOIN UNNEST(b.qty_price_arr) AS t(val)
GROUP BY b.s_store_name, b.web_site_name, b.d_month_seq
ORDER BY total_net_paid DESC
OFFSET 0 FETCH NEXT 20 ROWS ONLY
