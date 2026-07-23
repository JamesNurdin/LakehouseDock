WITH sales_union AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_sold_time_sk AS sold_time_sk,
        cs.cs_ship_date_sk AS ship_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_hdemo_sk AS bill_hdemo_sk,
        cs.cs_ship_hdemo_sk AS ship_hdemo_sk,
        cs.cs_catalog_page_sk AS catalog_page_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid AS net_paid,
        cs.cs_quantity AS quantity,
        cs.cs_ext_discount_amt AS ext_discount_amt,
        NULL AS web_site_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_sold_time_sk AS sold_time_sk,
        ws.ws_ship_date_sk AS ship_date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_hdemo_sk AS bill_hdemo_sk,
        ws.ws_ship_hdemo_sk AS ship_hdemo_sk,
        NULL AS catalog_page_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid AS net_paid,
        ws.ws_quantity AS quantity,
        ws.ws_ext_discount_amt AS ext_discount_amt,
        ws.ws_web_site_sk AS web_site_sk
    FROM web_sales ws
),
joined_data AS (
    SELECT
        su.order_number,
        su.sold_date_sk,
        su.sold_time_sk,
        su.ship_date_sk,
        su.item_sk,
        su.bill_hdemo_sk,
        su.ship_hdemo_sk,
        su.catalog_page_sk,
        su.promo_sk,
        su.net_profit,
        su.net_paid,
        su.quantity,
        su.ext_discount_amt,
        su.web_site_sk,
        d_sold.d_date AS sold_date,
        d_sold.d_year AS sold_year,
        d_ship.d_date AS ship_date,
        t_sold.t_time AS sold_time,
        t_ship.t_time AS ship_time,
        p_cs.p_promo_id,
        cp.cp_catalog_page_number,
        hd_bill.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        inv.inv_quantity_on_hand,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_fee,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        CASE
            WHEN su.net_profit > 10000 THEN 'High'
            WHEN su.net_profit BETWEEN 1000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM sales_union su
    LEFT JOIN date_dim d_sold ON su.sold_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_ship ON su.ship_date_sk = d_ship.d_date_sk
    LEFT JOIN time_dim t_sold ON su.sold_time_sk = t_sold.t_time_sk
    LEFT JOIN promotion p_cs ON su.promo_sk = p_cs.p_promo_sk
    LEFT JOIN catalog_page cp ON su.catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN household_demographics hd_bill ON su.bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv ON su.sold_date_sk = inv.inv_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = su.order_number AND cr.cr_item_sk = su.item_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN time_dim t_ship ON cr.cr_returned_time_sk = t_ship.t_time_sk
    LEFT JOIN household_demographics hd_ship ON su.ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN date_dim d_promo_start ON p_cs.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end ON p_cs.p_end_date_sk = d_promo_end.d_date_sk
    LEFT JOIN web_site ws_site ON su.web_site_sk = ws_site.web_site_sk
    LEFT JOIN date_dim d_ws_open ON ws_site.web_open_date_sk = d_ws_open.d_date_sk
    LEFT JOIN date_dim d_ws_close ON ws_site.web_close_date_sk = d_ws_close.d_date_sk
    LEFT JOIN catalog_page cp2 ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk
    LEFT JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    LEFT JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    LEFT JOIN time_dim t_sr_return ON sr.sr_return_time_sk = t_sr_return.t_time_sk
    LEFT JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
),
aggregated AS (
    SELECT
        jd.promo_sk,
        jd.p_promo_id,
        jd.sold_year,
        SUM(jd.net_profit) AS total_net_profit,
        SUM(jd.net_paid) AS total_net_paid,
        SUM(jd.quantity) AS total_quantity,
        SUM(jd.ext_discount_amt) AS total_discount,
        COUNT(DISTINCT jd.order_number) AS order_count,
        SUM(CASE WHEN jd.net_profit > 10000 THEN 1 ELSE 0 END) AS high_profit_orders,
        SUM(jd.cr_return_amount) AS total_catalog_return_amount,
        SUM(jd.sr_return_amt) AS total_store_return_amount,
        CASE
            WHEN SUM(jd.net_profit) > 500000 THEN 'Very High'
            WHEN SUM(jd.net_profit) > 100000 THEN 'High'
            WHEN SUM(jd.net_profit) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_level,
        (SELECT AVG(cs2.cs_ext_discount_amt)
         FROM catalog_sales cs2
         WHERE cs2.cs_promo_sk = jd.promo_sk) AS avg_catalog_discount
    FROM joined_data jd
    GROUP BY jd.promo_sk, jd.p_promo_id, jd.sold_year
    HAVING SUM(jd.net_profit) > 10000
)
SELECT
    a.promo_sk,
    a.p_promo_id,
    a.sold_year,
    a.total_net_profit,
    a.total_net_paid,
    a.total_quantity,
    a.order_count,
    a.high_profit_orders,
    a.total_catalog_return_amount,
    a.total_store_return_amount,
    a.profit_level,
    a.avg_catalog_discount,
    ROW_NUMBER() OVER (PARTITION BY a.sold_year ORDER BY a.total_net_profit DESC) AS profit_rank,
    SUM(a.total_net_profit) OVER (PARTITION BY a.sold_year) AS year_total_net_profit
FROM aggregated a
ORDER BY a.total_net_profit DESC
LIMIT 100
