WITH date_range AS (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-01-31'
    ),
    order_not_returned AS (
        SELECT cs.cs_order_number
        FROM catalog_sales cs
        WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_range)
        EXCEPT
        SELECT cr.cr_order_number
        FROM catalog_returns cr
        WHERE cr.cr_returned_date_sk IN (SELECT d_date_sk FROM date_range)
    )
SELECT
        st.s_market_desc,
        cp.cp_department,
        SUM(cs.cs_net_profit)                     AS catalog_profit,
        SUM(ss.ss_net_profit)                     AS store_profit,
        COUNT(DISTINCT cs.cs_item_sk)              AS distinct_catalog_items,
        COUNT(DISTINCT ss.ss_item_sk)              AS distinct_store_items,
        CASE
            WHEN SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) > 50000 THEN 'High'
            ELSE 'Low'
        END                                         AS profit_category,
        (SELECT COUNT(*) FROM order_not_returned) AS non_returned_orders_cnt
FROM catalog_sales cs
JOIN date_dim d_cs_sold
      ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN date_dim d_cs_ship
      ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cat
      ON cs.cs_ship_mode_sk = sm_cat.sm_ship_mode_sk
JOIN promotion p_cat
      ON cs.cs_promo_sk = p_cat.p_promo_sk
JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib_bill
      ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship
      ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
      ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
         AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN catalog_page cp_ret
      ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
LEFT JOIN ship_mode sm_ret
      ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
LEFT JOIN reason r_cr
      ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN customer_demographics cd_refund
      ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
LEFT JOIN household_demographics hd_refund
      ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
LEFT JOIN customer_address ca_refund
      ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
LEFT JOIN customer_demographics cd_returning
      ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
LEFT JOIN household_demographics hd_returning
      ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
LEFT JOIN customer_address ca_returning
      ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
-- Bridge both sales domains through the same calendar date
JOIN date_dim d_common
      ON cs.cs_sold_date_sk = d_common.d_date_sk
JOIN store_sales ss
      ON ss.ss_sold_date_sk = d_common.d_date_sk
JOIN date_dim d_ss_sold
      ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
JOIN store st
      ON ss.ss_store_sk = st.s_store_sk
JOIN promotion p_store
      ON ss.ss_promo_sk = p_store.p_promo_sk
LEFT JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
         AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN reason r_sr
      ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN date_dim d_sr_return
      ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
WHERE d_cs_sold.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-01-31'
GROUP BY st.s_market_desc, cp.cp_department
ORDER BY catalog_profit DESC
LIMIT 50
