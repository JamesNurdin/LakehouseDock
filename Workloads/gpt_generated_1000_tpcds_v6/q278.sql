WITH catalog_fact AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_sold_time_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cc.cc_state,
        i.i_category,
        i.i_product_name,
        cp.cp_department,
        p.p_discount_active,
        cd.cd_gender,
        hd.hd_income_band_sk,
        td.t_hour
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
),
store_fact AS (
    SELECT 
        sr.sr_item_sk,
        sr.sr_return_time_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        r.r_reason_desc,
        ca.ca_city,
        i.i_product_name AS sr_product_name,
        td.t_hour AS return_hour
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
),
web_fact AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sold_time_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wp.wp_url,
        w.w_warehouse_name,
        p.p_discount_active AS web_promo_active,
        i.i_product_name,
        cd.cd_gender AS web_gender,
        hd.hd_income_band_sk AS web_income_band,
        td.t_hour
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
)
SELECT
    cf.cs_item_sk AS item_sk,
    cf.i_product_name,
    cf.t_hour,
    SUM(cf.cs_ext_sales_price) AS total_catalog_sales,
    SUM(wf.ws_ext_sales_price) AS total_web_sales,
    SUM(sf.sr_return_amt) AS total_returns,
    SUM(cf.cs_net_profit + wf.ws_net_profit - sf.sr_net_loss) AS combined_profit
FROM catalog_fact cf
JOIN store_fact sf ON cf.cs_item_sk = sf.sr_item_sk
JOIN web_fact wf ON cf.cs_item_sk = wf.ws_item_sk
WHERE cf.cc_state = 'CA'
  AND cf.i_category = 'Electronics'
  AND cf.cp_department = 'Sports'
  AND cf.p_discount_active = 'Y'
  AND cf.cd_gender = 'M'
  AND cf.hd_income_band_sk = 5
  AND cf.t_hour BETWEEN 9 AND 17
  AND NOT EXISTS (
        SELECT 1 FROM inventory inv
        WHERE inv.inv_item_sk = cf.cs_item_sk
          AND inv.inv_quantity_on_hand = 0
    )
GROUP BY cf.cs_item_sk, cf.i_product_name, cf.t_hour
HAVING SUM(cf.cs_ext_sales_price) > 10000
ORDER BY combined_profit DESC
LIMIT 100
