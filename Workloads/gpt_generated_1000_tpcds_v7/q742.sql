WITH base AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        cp.cp_department,
        cs.cs_net_profit,
        ss.ss_net_paid,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        sm.sm_carrier,
        w.w_warehouse_name
    FROM tpcds.date_dim d
    JOIN tpcds.promotion p
        ON p.p_start_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND cp.cp_type = 'ELECTRONICS'
      AND sm.sm_carrier = 'USPS'
      AND ib.ib_upper_bound <= 80000
),
agg AS (
    SELECT
        cp_department            AS department,
        p_promo_name             AS promo_name,
        cs_net_profit            AS profit,
        ss_net_paid              AS net_paid
    FROM base
)
SELECT
    department,
    promo_name,
    SUM(profit)               AS total_profit,
    AVG(net_paid)             AS avg_net_paid
FROM agg
GROUP BY department, promo_name
HAVING SUM(profit) > 10000
ORDER BY total_profit DESC
LIMIT 10
