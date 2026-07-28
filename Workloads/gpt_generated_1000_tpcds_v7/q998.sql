WITH sales_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit)          AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.time_dim td               ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.promotion p               ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca       ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.inventory inv             ON w.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN tpcds.web_returns wr           ON wr.wr_refunded_customer_sk = c.c_customer_sk
                                         AND wr.wr_returned_time_sk = td.t_time_sk
    JOIN tpcds.reason r                  ON wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_page wp               ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND ib.ib_upper_bound >= 60000
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
)
SELECT AVG(total_profit) AS avg_warehouse_profit
FROM sales_agg
WHERE total_profit > 10000
