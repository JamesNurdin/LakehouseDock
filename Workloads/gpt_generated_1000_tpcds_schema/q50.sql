WITH joined AS (
    SELECT
        d.d_year AS d_year,
        w.w_city AS w_city,
        sm.sm_type AS sm_type,
        ss.ss_net_paid AS ss_net_paid,
        c.c_customer_sk AS c_customer_sk,
        i.inv_quantity_on_hand AS inv_quantity_on_hand,
        (SELECT MAX(p2.p_cost)
         FROM tpcds.promotion p2
         WHERE p2.p_start_date_sk = d.d_date_sk) AS max_promo_cost
    FROM tpcds.date_dim d
    JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.call_center call_c
        ON call_c.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND t.t_hour = 15
      AND c.c_preferred_cust_flag = 'Y'
      AND w.w_city = 'Pleasant Grove'
      AND p.p_discount_active = 'Y'
      AND i.inv_quantity_on_hand > 0
      AND NOT EXISTS (
            SELECT 1 FROM tpcds.store_returns sr2
            WHERE sr2.sr_ticket_number = ss.ss_ticket_number
          )
)
SELECT
    d_year,
    w_city,
    sm_type,
    SUM(ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    AVG(inv_quantity_on_hand) AS avg_inventory_qty,
    MAX(max_promo_cost) AS max_promo_cost_overall
FROM joined
GROUP BY ROLLUP (d_year, w_city, sm_type)
LIMIT 100
