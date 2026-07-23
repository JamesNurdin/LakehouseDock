WITH us_web_sites AS (
    SELECT DISTINCT web_site_sk
    FROM web_site
    WHERE web_country = 'United States'
)
SELECT
    cc.cc_name,
    w.web_name,
    cp.cp_type,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    t.t_hour,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(sr.sr_return_amt) AS total_store_returns,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(cs.cs_quantity) AS avg_catalog_quantity,
    CASE
        WHEN SUM(cs.cs_ext_sales_price) > 10000 THEN 'High'
        ELSE 'Low'
    END AS sales_volume_category,
    (SELECT MAX(cs2.cs_net_profit) FROM catalog_sales cs2) AS max_catalog_net_profit
FROM
    call_center cc
    JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    cc.cc_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
    AND hd.hd_buy_potential = '1001-5000'
    AND ib.ib_lower_bound >= 50000
    AND w.web_site_sk IN (SELECT web_site_sk FROM us_web_sites)
    AND sr.sr_return_quantity > 5
    AND cs.cs_quantity > 2
GROUP BY
    cc.cc_name,
    w.web_name,
    cp.cp_type,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    t.t_hour
ORDER BY
    total_catalog_sales DESC
LIMIT 100
