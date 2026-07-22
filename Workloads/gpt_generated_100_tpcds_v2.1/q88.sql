WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        d1.d_year,
        w.w_state,
        i.i_brand,
        cc.cc_name,
        ws_site.web_name,
        i.i_current_price,
        d1.d_date AS sale_date,
        hd_bill.hd_buy_potential
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d1.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN date_dim d3 ON wr.wr_returned_date_sk = d3.d_date_sk
    LEFT JOIN date_dim d4 ON cr.cr_returned_date_sk = d4.d_date_sk
    -- Additional joins to satisfy remaining rules for web_sales
    LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN customer_address ca_bill_ws ON ws.ws_bill_addr_sk = ca_bill_ws.ca_address_sk
    LEFT JOIN customer_address ca_ship_ws ON ws.ws_ship_addr_sk = ca_ship_ws.ca_address_sk
    LEFT JOIN customer_demographics cd_bill_ws ON ws.ws_bill_cdemo_sk = cd_bill_ws.cd_demo_sk
    LEFT JOIN customer_demographics cd_ship_ws ON ws.ws_ship_cdemo_sk = cd_ship_ws.cd_demo_sk
    LEFT JOIN household_demographics hd_bill_ws ON ws.ws_bill_hdemo_sk = hd_bill_ws.hd_demo_sk
    LEFT JOIN household_demographics hd_ship_ws ON ws.ws_ship_hdemo_sk = hd_ship_ws.hd_demo_sk
)
SELECT
    d_year,
    w_state,
    i_brand,
    cc_name,
    web_name,
    SUM(cs_net_paid) AS total_sales,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(sr_return_amt) AS total_store_return_amount,
    SUM(wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT cs_order_number) AS order_count,
    AVG(i_current_price) AS avg_item_price,
    MIN(sale_date) AS first_sale_date,
    MAX(sale_date) AS last_sale_date
FROM base
WHERE d_year = 2001
  AND w_state = 'CA'
  AND i_brand = 'Brand#12'
  AND hd_buy_potential = '5001-10000'
GROUP BY d_year, w_state, i_brand, cc_name, web_name
UNION ALL
SELECT
    d_year,
    w_state,
    i_brand,
    cc_name,
    web_name,
    SUM(cs_net_paid) AS total_sales,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(sr_return_amt) AS total_store_return_amount,
    SUM(wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT cs_order_number) AS order_count,
    AVG(i_current_price) AS avg_item_price,
    MIN(sale_date) AS first_sale_date,
    MAX(sale_date) AS last_sale_date
FROM base
WHERE d_year = 2002
  AND w_state = 'TX'
  AND i_brand = 'Brand#13'
  AND hd_buy_potential = '1001-5000'
GROUP BY d_year, w_state, i_brand, cc_name, web_name
ORDER BY d_year, w_state, i_brand
LIMIT 100
