WITH base AS (
    SELECT
        d.d_year,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        c.c_customer_sk,
        c.c_birth_month,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        sr.sr_ticket_number,
        r.r_reason_desc,
        cs.cs_sold_date_sk,
        cs.cs_net_profit AS cs_net_profit,
        ss.ss_net_profit AS ss_net_profit,
        p.p_promo_sk,
        p.p_discount_active,
        cc.cc_call_center_sk,
        cp.cp_catalog_page_sk,
        w.w_warehouse_sk,
        i.inv_quantity_on_hand
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
        AND i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND c.c_birth_month IN (3, 4, 5)
      AND hd.hd_buy_potential = '1001-5000'
      AND p.p_discount_active = 'Y'
      AND i.inv_quantity_on_hand > 100
)
SELECT DISTINCT
    d_year,
    s_store_name,
    total_profit,
    profit_rank
FROM (
    SELECT
        d_year,
        s_store_name,
        SUM(ss_net_profit + cs_net_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(ss_net_profit + cs_net_profit) DESC) AS profit_rank
    FROM base
    GROUP BY d_year, s_store_name
    HAVING SUM(ss_net_profit + cs_net_profit) > 10000
) ranked
ORDER BY profit_rank, s_store_name
LIMIT 100
