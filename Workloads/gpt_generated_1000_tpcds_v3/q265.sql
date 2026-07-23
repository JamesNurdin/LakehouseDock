WITH distinct_promos AS (
    SELECT DISTINCT
        p_promo_sk,
        p_promo_name,
        p_discount_active,
        p_start_date_sk,
        p_end_date_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
),
joined_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_wholesale_cost,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_web_site_sk,
        d_sold.d_date AS sold_date,
        d_sold.d_year,
        t_sold.t_hour AS sold_hour,
        cd_bill.cd_gender AS bill_gender,
        cd_bill.cd_education_status AS bill_education,
        promo.p_promo_name,
        site.web_name,
        sm.sm_type,
        inv.inv_quantity_on_hand,
        cc.cc_name,
        cc.cc_state,
        cc.cc_sq_ft,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        sr.sr_fee,
        sr.sr_store_credit,
        d_return.d_date AS return_date,
        t_return.t_hour AS return_hour,
        cd_ret.cd_gender AS return_gender,
        d_ws_open.d_date AS site_open_date,
        d_ws_close.d_date AS site_close_date,
        d_promo_start.d_date AS promo_start_date,
        d_promo_end.d_date AS promo_end_date,
        d_cc_closed.d_date AS cc_closed_date,
        d_cp_end.d_date AS cp_end_date,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM web_sales ws
    INNER JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    INNER JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    INNER JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN distinct_promos promo
        ON ws.ws_promo_sk = promo.p_promo_sk
    INNER JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    INNER JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    INNER JOIN call_center cc
        ON cc.cc_open_date_sk = d_sold.d_date_sk
    INNER JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_sold.d_date_sk
    INNER JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_sold.d_date_sk
    INNER JOIN time_dim t_return
        ON sr.sr_return_time_sk = t_return.t_time_sk
    INNER JOIN customer_demographics cd_ret
        ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    INNER JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    INNER JOIN date_dim d_ws_open
        ON site.web_open_date_sk = d_ws_open.d_date_sk
    INNER JOIN date_dim d_ws_close
        ON site.web_close_date_sk = d_ws_close.d_date_sk
    INNER JOIN date_dim d_promo_start
        ON promo.p_start_date_sk = d_promo_start.d_date_sk
    INNER JOIN date_dim d_promo_end
        ON promo.p_end_date_sk = d_promo_end.d_date_sk
    INNER JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    INNER JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE
        d_sold.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
        AND ws.ws_ext_wholesale_cost > 2000
        AND cd_bill.cd_education_status = 'College'
        AND cc.cc_state = 'CA'
        AND sm.sm_type = 'AIR'
        AND inv.inv_quantity_on_hand > 1000
        AND sr.sr_fee > 50
        AND sr.sr_store_credit > 10
)
SELECT
    jd.ws_order_number,
    jd.sold_date,
    jd.ws_quantity,
    jd.ws_ext_wholesale_cost,
    jd.ws_net_profit,
    jd.profit_flag,
    jd.web_name,
    jd.sm_type,
    jd.p_promo_name,
    jd.cc_name,
    jd.cc_state,
    jd.cc_sq_ft,
    jd.cp_department,
    jd.sr_fee,
    jd.sr_store_credit,
    DENSE_RANK() OVER (PARTITION BY jd.web_name ORDER BY jd.ws_net_profit DESC) AS net_profit_rank,
    ROW_NUMBER() OVER (PARTITION BY jd.web_name ORDER BY jd.sold_date, jd.ws_order_number) AS sale_seq
FROM joined_data jd
ORDER BY net_profit_rank ASC, jd.ws_order_number
LIMIT 100
