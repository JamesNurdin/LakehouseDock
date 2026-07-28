-- goal: Analyze net sales per customer‑item combination across all sales channels, applying filters on price, purchase estimate, sales hour, call‑center state and household income; flag profit/loss and rank customers by sales using window functions.
WITH joined_data AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        cs.cs_ext_sales_price        AS sales_price,
        cr.cr_return_amount          AS return_amount,
        cc.cc_state,
        td.t_hour,
        i.i_current_price,
        cd.cd_purchase_estimate,
        ib.ib_upper_bound
    FROM time_dim td
    JOIN catalog_sales cs       ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN store_sales ss         ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN web_sales ws           ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN catalog_returns cr    ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i                 ON i.i_item_sk = cs.cs_item_sk
                                 AND i.i_item_sk = ss.ss_item_sk
                                 AND i.i_item_sk = ws.ws_item_sk
                                 AND i.i_item_sk = cr.cr_item_sk
    JOIN customer c             ON c.c_customer_sk = cs.cs_bill_customer_sk
                                 AND c.c_customer_sk = ss.ss_customer_sk
                                 AND c.c_customer_sk = ws.ws_bill_customer_sk
                                 AND c.c_customer_sk = cr.cr_refunded_customer_sk
    JOIN customer_address ca    ON ca.ca_address_sk = cs.cs_bill_addr_sk
                                 AND ca.ca_address_sk = ss.ss_addr_sk
                                 AND ca.ca_address_sk = ws.ws_bill_addr_sk
                                 AND ca.ca_address_sk = cr.cr_refunded_addr_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
                                 AND cd.cd_demo_sk = ss.ss_cdemo_sk
                                 AND cd.cd_demo_sk = ws.ws_bill_cdemo_sk
                                 AND cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
                                 AND hd.hd_demo_sk = ss.ss_hdemo_sk
                                 AND hd.hd_demo_sk = ws.ws_bill_hdemo_sk
                                 AND hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
    JOIN income_band ib          ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN promotion p             ON p.p_promo_sk = cs.cs_promo_sk
                                 AND p.p_promo_sk = ws.ws_promo_sk
    JOIN ship_mode sm            ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
                                 AND sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
                                 AND sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    JOIN call_center cc          ON cc.cc_call_center_sk = cs.cs_call_center_sk
                                 AND cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN web_site ws_site        ON ws_site.web_site_sk = ws.ws_web_site_sk
    WHERE
        i.i_current_price > 100
        AND cd.cd_purchase_estimate BETWEEN 6000 AND 10000
        AND td.t_hour BETWEEN 10 AND 16
        AND cc.cc_state = 'CA'
        AND ib.ib_upper_bound <= 50000
)
SELECT
    c_customer_id,
    i_item_id,
    SUM(sales_price)                              AS total_sales,
    SUM(return_amount)                            AS total_returns,
    SUM(sales_price) - SUM(return_amount)         AS net_sales,
    CASE WHEN SUM(sales_price) - SUM(return_amount) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY SUM(sales_price) DESC) AS sales_rank,
    SUM(SUM(sales_price)) OVER (PARTITION BY c_customer_id) AS cumulative_sales_per_customer
FROM joined_data
GROUP BY c_customer_id, i_item_id
ORDER BY net_sales DESC
LIMIT 100
