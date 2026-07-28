WITH base AS (
    SELECT
        s.s_store_name                AS s_store_name,
        d_sold.d_year                AS d_year,
        sm.sm_type                   AS sm_type,
        cs.cs_net_profit             AS cs_net_profit,
        cs.cs_order_number           AS cs_order_number
    FROM store_sales ss
    JOIN date_dim d_sold
      ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd1
      ON ss.ss_cdemo_sk = cd1.cd_demo_sk
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory i
      ON i.inv_date_sk = d_sold.d_date_sk
    JOIN catalog_sales cs
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
      ON wr.wr_returned_date_sk = d_sold.d_date_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    -- Re‑use date_dim under a different alias for the ship date of the catalog sale
    JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk
    -- Re‑use customer_demographics under a different alias for the ship‑customer demographics
    JOIN customer_demographics cd2
      ON cs.cs_ship_cdemo_sk = cd2.cd_demo_sk
),
agg AS (
    SELECT
        s_store_name,
        d_year,
        sm_type,
        SUM(cs_net_profit)        AS total_profit,
        COUNT(DISTINCT cs_order_number) AS distinct_orders
    FROM base
    GROUP BY s_store_name, d_year, sm_type
)
SELECT
    s_store_name,
    d_year,
    sm_type,
    total_profit,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY sm_type ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 100
