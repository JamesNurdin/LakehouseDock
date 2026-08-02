WITH combined AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_quantity,
        sr.sr_ticket_number,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_quantity,
        s.s_store_sk,
        s.s_market_manager,
        hd_bill.hd_income_band_sk,
        td1.t_hour AS cs_hour,
        td2.t_hour AS ws_hour,
        td3.t_hour AS sr_hour
    FROM item i
    INNER JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN promotion p1 ON cs.cs_promo_sk = p1.p_promo_sk
    INNER JOIN ship_mode sm1 ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
    INNER JOIN time_dim td1 ON cs.cs_sold_time_sk = td1.t_time_sk
    INNER JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN income_band ib1 ON hd_bill.hd_income_band_sk = ib1.ib_income_band_sk
    INNER JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
    INNER JOIN time_dim td2 ON ws.ws_sold_time_sk = td2.t_time_sk
    INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    INNER JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    INNER JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    INNER JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    INNER JOIN income_band ib2 ON hd_ws_bill.hd_income_band_sk = ib2.ib_income_band_sk
    FULL OUTER JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN time_dim td3 ON sr.sr_return_time_sk = td3.t_time_sk
    FULL OUTER JOIN store s ON sr.sr_store_sk = s.s_store_sk
),
aggregated AS (
    SELECT
        i_item_id,
        i_product_name,
        i_current_price,
        s_market_manager,
        hd_income_band_sk,
        cs_hour,
        SUM(COALESCE(cs_net_paid, 0)) AS total_catalog_net_paid,
        SUM(COALESCE(ws_net_paid, 0)) AS total_web_net_paid,
        SUM(COALESCE(sr_return_amt_inc_tax, 0)) AS total_store_return_amt
    FROM combined
    WHERE i_current_price > 100
      AND i_current_price < 500
      AND cs_quantity > 2
      AND hd_income_band_sk IN (2, 7, 12)
      AND s_market_manager = 'John Sizemore'
      AND cs_hour BETWEEN 9 AND 17
      AND ws_net_paid > 500
    GROUP BY i_item_id, i_product_name, i_current_price, s_market_manager, hd_income_band_sk, cs_hour
)
SELECT
    i_item_id,
    i_product_name,
    i_current_price,
    s_market_manager,
    hd_income_band_sk,
    cs_hour,
    total_catalog_net_paid,
    total_web_net_paid,
    total_store_return_amt,
    (total_catalog_net_paid + total_web_net_paid - total_store_return_amt) AS net_total,
    ROW_NUMBER() OVER (ORDER BY (total_catalog_net_paid + total_web_net_paid - total_store_return_amt) DESC) AS sales_rank
FROM aggregated
ORDER BY net_total DESC
LIMIT 100
