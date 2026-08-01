WITH ss_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (5)
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    ss.ss_ticket_number,
    ss.ss_net_profit,
    cs.cs_net_profit,
    (ss.ss_net_profit + cs.cs_net_profit) AS total_net_profit,
    RANK() OVER (ORDER BY (ss.ss_net_profit + cs.cs_net_profit) DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d.d_date_sk DESC) AS recent_txn_seq,
    cc.cc_name,
    p_ss.p_promo_name   AS store_promo,
    p_cs.p_promo_name   AS catalog_promo,
    sm.sm_type,
    w.w_warehouse_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cr.cr_fee,
    wr.wr_return_quantity,
    wp.wp_url
FROM ss_sample ss
JOIN date_dim d               ON ss.ss_sold_date_sk      = d.d_date_sk
JOIN customer c               ON ss.ss_customer_sk      = c.c_customer_sk
JOIN customer_address ca_ss   ON ss.ss_addr_sk          = ca_ss.ca_address_sk
JOIN promotion p_ss           ON ss.ss_promo_sk         = p_ss.p_promo_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk      = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk    = hd_ss.hd_demo_sk
JOIN income_band ib           ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_sales cs         ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN promotion p_cs           ON cs.cs_promo_sk         = p_cs.p_promo_sk
JOIN call_center cc           ON cs.cs_call_center_sk   = cc.cc_call_center_sk
JOIN ship_mode sm             ON cs.cs_ship_mode_sk     = sm.sm_ship_mode_sk
JOIN warehouse w              ON cs.cs_warehouse_sk     = w.w_warehouse_sk
JOIN customer_address ca_cs   ON cs.cs_bill_addr_sk     = ca_cs.ca_address_sk
JOIN catalog_returns cr       ON cr.cr_item_sk          = cs.cs_item_sk
                             AND cr.cr_order_number   = cs.cs_order_number
JOIN web_returns wr           ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN web_page wp              ON wr.wr_web_page_sk     = wp.wp_web_page_sk
WHERE d.d_year = 2001
  AND d.d_quarter_seq BETWEEN 10 AND 20
  AND cs.cs_quantity > 2
  AND cr.cr_fee > 20
  AND p_cs.p_discount_active = 'Y'
  AND sm.sm_type = 'AIR'
  AND cc.cc_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number
          AND cr2.cr_fee > 30
      )
ORDER BY profit_rank
LIMIT 100
