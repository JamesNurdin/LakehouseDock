WITH
-- Customers that are preferred and also have a high‑cost web shipment
qualifying_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
    INTERSECT
    SELECT c2.c_customer_sk
    FROM customer c2
    WHERE EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = c2.c_customer_sk
          AND ws.ws_ext_ship_cost > 2000
    )
),
-- Union of store‑sales and web‑sales after applying the same business filters
union_sales AS (
    SELECT
        s.s_store_sk,
        d.d_year,
        ss.ss_net_paid               AS net_paid,
        c.c_customer_sk,
        ib.ib_lower_bound,
        CAST(NULL AS VARCHAR)        AS sm_type
    FROM date_dim d
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND c.c_birth_year BETWEEN 1950 AND 1990
      AND s.s_state = 'TX'
      AND ib.ib_lower_bound >= 30000
      AND EXISTS (SELECT 1 FROM qualifying_customers qc WHERE qc.c_customer_sk = c.c_customer_sk)

    UNION

    SELECT
        s.s_store_sk,
        d.d_year,
        ws.ws_net_paid               AS net_paid,
        c.c_customer_sk,
        ib.ib_lower_bound,
        sm.sm_type
    FROM date_dim d
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND c.c_birth_year BETWEEN 1950 AND 1990
      AND s.s_state = 'TX'
      AND ib.ib_lower_bound >= 30000
      AND sm.sm_type = 'AIR'
      AND EXISTS (SELECT 1 FROM qualifying_customers qc WHERE qc.c_customer_sk = c.c_customer_sk)
),
-- Aggregate per store and year
agg_sales AS (
    SELECT
        s_store_sk,
        d_year,
        SUM(net_paid)                                 AS total_net_paid,
        COUNT(*)                                      AS sales_cnt,
        CASE WHEN SUM(net_paid) > 500000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM union_sales
    GROUP BY s_store_sk, d_year
),
-- Apply a window function to rank stores by revenue
final_rank AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn,
        s_store_sk,
        d_year,
        total_net_paid,
        sales_cnt,
        profit_category
    FROM agg_sales
)
SELECT
    rn,
    s_store_sk,
    d_year,
    total_net_paid,
    sales_cnt,
    profit_category
FROM final_rank
ORDER BY total_net_paid DESC
OFFSET 0 LIMIT 100
