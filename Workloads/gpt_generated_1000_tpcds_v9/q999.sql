WITH aggregated AS (
    SELECT
        cc.cc_name AS call_center,
        p.p_promo_name AS promotion,
        sm.sm_type AS ship_mode,
        hd.hd_buy_potential AS buy_potential,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(cr.cr_refunded_cash) AS catalog_refunds,
        SUM(sr.sr_return_amt) AS store_returns,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(wr.wr_refunded_cash) AS web_refunds
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk

    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk

    LEFT JOIN store_returns sr
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk

    LEFT JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk

    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk

    WHERE
        cc.cc_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND sm.sm_type = 'AIR'
        AND hd.hd_income_band_sk BETWEEN 5 AND 10
        AND wp.wp_char_count > 5000
        AND cc.cc_rec_start_date >= DATE '2000-01-01'
    GROUP BY GROUPING SETS (
        (cc.cc_name, p.p_promo_name, sm.sm_type, hd.hd_buy_potential),
        (cc.cc_name, p.p_promo_name, sm.sm_type),
        (cc.cc_name, p.p_promo_name),
        (cc.cc_name),
        ()
    )
)
SELECT
    call_center,
    promotion,
    ship_mode,
    buy_potential,
    catalog_sales,
    catalog_refunds,
    store_returns,
    web_sales,
    web_refunds,
    (catalog_sales + web_sales - catalog_refunds - store_returns - web_refunds) AS net_sales,
    RANK() OVER (ORDER BY (catalog_sales + web_sales - catalog_refunds - store_returns - web_refunds) DESC) AS sales_rank,
    SUM((catalog_sales + web_sales - catalog_refunds - store_returns - web_refunds)) OVER (
        ORDER BY call_center ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_net_sales
FROM aggregated
ORDER BY net_sales DESC
LIMIT 100
