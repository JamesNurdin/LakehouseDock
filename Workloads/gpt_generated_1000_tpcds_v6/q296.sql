WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cr.cr_return_amount,
        ws.ws_net_profit,
        wr.wr_return_amt,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        d_year.d_year,
        hd_bill.hd_buy_potential,
        hd_ship.hd_vehicle_count,
        cs.cs_bill_customer_sk AS bill_cust_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_year ON cs.cs_sold_date_sk = d_year.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d_year.d_date_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d_year.d_date_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN date_dim d_site_open ON we.web_open_date_sk = d_site_open.d_date_sk
    JOIN date_dim d_site_close ON we.web_close_date_sk = d_site_close.d_date_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE d_year.d_year = 2000
      AND p.p_discount_active = 'Y'
)
SELECT
    i_item_id,
    i_category,
    i_brand,
    p_promo_name,
    d_year,
    SUM(cs_net_profit) AS total_net_profit,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ws_net_profit) AS total_web_net_profit,
    SUM(wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    AVG(CASE WHEN hd_buy_potential = '1001-5000' THEN 1 ELSE 0 END) AS pct_buy_potential_1001_5000
FROM base_sales
WHERE EXISTS (
    SELECT 1 FROM customer c
    WHERE c.c_customer_sk = base_sales.bill_cust_sk
      AND c.c_preferred_cust_flag = 'Y'
)
GROUP BY i_item_id, i_category, i_brand, p_promo_name, d_year
HAVING SUM(cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
