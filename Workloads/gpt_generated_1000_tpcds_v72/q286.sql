/* goal: Rank stores in California for year 2001 by combined store and catalog sales profit, filtering on high‑income households and active promotions, while excluding stores with large returns */
WITH base AS (
    SELECT DISTINCT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        ss.ss_net_profit,
        cs.cs_net_profit,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_discount_active
    FROM tpcds.store AS s
    JOIN tpcds.store_sales AS ss
      ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.date_dim AS d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer AS c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address AS ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics AS hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band AS ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.promotion AS p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.time_dim AS t
      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.store_returns AS sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.reason AS r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.catalog_sales AS cs
      ON cs.cs_bill_customer_sk = c.c_customer_sk
     AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
     AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.call_center AS cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page AS cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode AS sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse AS w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.inventory AS i
      ON i.inv_warehouse_sk = w.w_warehouse_sk
     AND i.inv_date_sk = d.d_date_sk
    WHERE s.s_state = 'CA'
      AND ib.ib_lower_bound >= 50000
      AND d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND NOT EXISTS (
          SELECT 1 FROM tpcds.store_returns AS sr2
          WHERE sr2.sr_store_sk = s.s_store_sk
            AND sr2.sr_return_amt > 1000
      )
),
agg AS (
    SELECT
        s_store_id,
        s_store_name,
        s_state,
        d_year,
        SUM(ss_net_profit) AS total_store_sales_profit,
        SUM(cs_net_profit) AS total_catalog_sales_profit,
        SUM(ss_net_profit) + SUM(cs_net_profit) AS total_profit
    FROM base
    GROUP BY s_store_id, s_store_name, s_state, d_year
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.s_state,
    a.d_year,
    a.total_store_sales_profit,
    a.total_catalog_sales_profit,
    a.total_profit,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_profit DESC) AS profit_rank
FROM agg AS a
ORDER BY a.d_year, profit_rank
LIMIT 100
