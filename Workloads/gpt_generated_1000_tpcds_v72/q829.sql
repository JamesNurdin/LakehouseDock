WITH joined AS (
    SELECT
        s.s_store_name,
        d1.d_year AS sale_year,
        i.i_item_id,
        i.i_brand,
        ws.ws_net_paid,
        ss.ss_net_paid_inc_tax,
        cr.cr_return_amount,
        sr.sr_return_amt,
        cd.cd_credit_rating,
        hd.hd_buy_potential,
        CASE WHEN cd.cd_credit_rating = 'Good' THEN 'Preferred' ELSE 'Other' END AS customer_type,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM store_sales ss
    JOIN date_dim d1               ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN time_dim t1               ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN item i                    ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c                ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s                   ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk

    -- store returns linked by ticket number and item/store
    JOIN store_returns sr          ON sr.sr_ticket_number = ss.ss_ticket_number
                                   AND sr.sr_item_sk = ss.ss_item_sk
                                   AND sr.sr_store_sk = s.s_store_sk
    JOIN reason r                  ON sr.sr_reason_sk = r.r_reason_sk

    -- catalog returns linked through the same item and date
    JOIN catalog_returns cr        ON cr.cr_item_sk = i.i_item_sk
                                   AND cr.cr_returned_date_sk = d1.d_date_sk
    JOIN call_center cc            ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm              ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w               ON cr.cr_warehouse_sk = w.w_warehouse_sk

    -- web sales linked through item and date
    JOIN web_sales ws              ON ws.ws_item_sk = i.i_item_sk
                                   AND ws.ws_sold_date_sk = d1.d_date_sk
    JOIN web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we               ON ws.ws_web_site_sk = we.web_site_sk
    JOIN date_dim d_ws_ship        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk

    -- inventory for the same item, date and warehouse
    JOIN inventory inv             ON inv.inv_item_sk = i.i_item_sk
                                   AND inv.inv_date_sk = d1.d_date_sk
                                   AND inv.inv_warehouse_sk = w.w_warehouse_sk

    -- income band through household demographics
    JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk

    -- additional date joins to satisfy join rules (left joins because they are not needed for filters)
    LEFT JOIN date_dim d_cc_open   ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    LEFT JOIN date_dim d_cc_close  ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
    LEFT JOIN date_dim d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
    LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    LEFT JOIN date_dim d_sr_ret    ON sr.sr_returned_date_sk = d_sr_ret.d_date_sk
    LEFT JOIN date_dim d_customer_first_ship ON c.c_first_shipto_date_sk = d_customer_first_ship.d_date_sk
)
SELECT *
FROM joined
WHERE sale_year = 2001
  AND i_brand = 'Brand#12'
  AND ws_net_paid > 500
  AND cd_credit_rating = 'Good'
ORDER BY sales_rank
LIMIT 100
