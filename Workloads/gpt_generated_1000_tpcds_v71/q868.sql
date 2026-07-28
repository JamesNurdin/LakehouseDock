/* goal: Identify the top customers by combined profit from catalog, store, and web sales while applying multiple business filters, using joins across all TPC‑DS tables, a scalar subquery, and a ranking window function */
WITH joined_data AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cp.cp_department,
        sm.sm_type,
        cs.cs_quantity,
        cs.cs_net_profit        AS catalog_net_profit,
        ss.ss_net_profit        AS store_net_profit,
        ws.ws_net_profit        AS web_net_profit,
        ws.ws_coupon_amt,
        ca.ca_state,
        c.c_birth_year,
        cp.cp_start_date_sk,
        cp.cp_end_date_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    JOIN store_sales ss
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE cp.cp_start_date_sk >= 2450800
      AND cp.cp_end_date_sk   <= 2451300
      AND sm.sm_type IN ('AIR', 'GROUND')
      AND ca.ca_state = 'CA'
      AND c.c_birth_year BETWEEN 1960 AND 1970
      AND cs.cs_quantity > 1
      AND ws.ws_coupon_amt > 500
)
SELECT
    jd.c_customer_id,
    jd.c_first_name,
    jd.c_last_name,
    jd.cp_department,
    jd.sm_type,
    SUM(jd.catalog_net_profit) AS total_catalog_profit,
    SUM(jd.store_net_profit)   AS total_store_profit,
    SUM(jd.web_net_profit)     AS total_web_profit,
    (SUM(jd.catalog_net_profit) + SUM(jd.store_net_profit) + SUM(jd.web_net_profit)) AS total_profit,
    RANK() OVER (ORDER BY (SUM(jd.catalog_net_profit) + SUM(jd.store_net_profit) + SUM(jd.web_net_profit)) DESC) AS profit_rank,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_catalog_profit
FROM joined_data jd
GROUP BY
    jd.c_customer_id,
    jd.c_first_name,
    jd.c_last_name,
    jd.cp_department,
    jd.sm_type
ORDER BY profit_rank, total_profit DESC
LIMIT 100
