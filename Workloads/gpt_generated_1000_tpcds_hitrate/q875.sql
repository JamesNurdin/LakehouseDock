-- Goal: Analyse combined store and web sales performance for 2001, grouped by date and state, 
-- including customer counts, total and average net paid, while demonstrating full outer join, right outer join, and scalar subqueries.
WITH
-- Store side aggregation (store_sales fact + dimensions)
store_agg AS (
    SELECT
        d.d_date AS sales_date,
        c.c_customer_sk,
        ca.ca_state,
        s.s_store_sk,
        p.p_promo_sk,
        hd.hd_buy_potential,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d          ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t          ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c          ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s             ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p         ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND c.c_preferred_cust_flag = 'Y'
      AND ca.ca_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_date, c.c_customer_sk, ca.ca_state, s.s_store_sk, p.p_promo_sk, hd.hd_buy_potential
),

-- Web side aggregation (web_sales fact + dimensions)
web_agg AS (
    SELECT
        d.d_date AS sales_date,
        c.c_customer_sk,
        ca.ca_state,
        wh.w_warehouse_sk,
        sm.sm_ship_mode_sk,
        p.p_promo_sk,
        hd.hd_buy_potential,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d            ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t            ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c            ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca   ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse wh          ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN ship_mode sm          ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p           ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND c.c_preferred_cust_flag = 'Y'
      AND ca.ca_state = 'TX'
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_date, c.c_customer_sk, ca.ca_state, wh.w_warehouse_sk, sm.sm_ship_mode_sk, p.p_promo_sk, hd.hd_buy_potential
),

-- Combine store and web aggregates, preserving unmatched rows from both sides
combined AS (
    SELECT
        COALESCE(sa.sales_date, wa.sales_date) AS sales_date,
        COALESCE(sa.c_customer_sk, wa.c_customer_sk) AS customer_sk,
        COALESCE(sa.ca_state, wa.ca_state) AS state,
        sa.s_store_sk,
        wa.w_warehouse_sk,
        COALESCE(sa.p_promo_sk, wa.p_promo_sk) AS promo_sk,
        COALESCE(sa.total_net_paid, 0) + COALESCE(wa.total_net_paid, 0) AS total_net_paid,
        COALESCE(sa.total_net_profit, 0) + COALESCE(wa.total_net_profit, 0) AS total_net_profit,
        COALESCE(sa.hd_buy_potential, wa.hd_buy_potential) AS buy_potential
    FROM store_agg sa
    FULL OUTER JOIN web_agg wa
        ON sa.sales_date = wa.sales_date
       AND sa.c_customer_sk = wa.c_customer_sk
),

-- Reason aggregation using RIGHT OUTER JOIN to keep all reasons (even with no returns)
reason_agg AS (
    SELECT
        r.r_reason_desc,
        COUNT(sr.sr_ticket_number) AS return_cnt
    FROM reason r
    RIGHT OUTER JOIN store_returns sr
        ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
)

SELECT
    c.sales_date,
    c.state,
    COUNT(DISTINCT c.customer_sk) AS unique_customers,
    SUM(c.total_net_paid) AS sum_net_paid,
    AVG(c.total_net_paid) AS avg_net_paid,
    SUM(c.total_net_profit) AS sum_net_profit,
    -- scalar subquery: compare average net paid against average promotion cost
    CASE WHEN SUM(c.total_net_paid) > (SELECT AVG(p_cost) FROM promotion) * 10 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category,
    -- existence check: are there any web returns for reason 'Damaged'?
    EXISTS (SELECT 1 FROM web_returns wr
            JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
            WHERE r.r_reason_desc = 'Damaged') AS has_damaged_web_returns,
    -- include a value from reason_agg to guarantee the reason table is used
    (SELECT COALESCE(MAX(return_cnt),0) FROM reason_agg) AS max_reason_return_cnt
FROM combined c
LEFT JOIN store_returns sr ON sr.sr_ticket_number = c.promo_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE c.state IS NOT NULL
  AND c.buy_potential IS NOT NULL
  AND c.sales_date >= DATE '2001-01-01'
  AND c.sales_date <= DATE '2001-12-31'
GROUP BY c.sales_date, c.state, c.buy_potential
HAVING SUM(c.total_net_paid) > (SELECT AVG(p_cost) FROM promotion)
ORDER BY sum_net_paid DESC
LIMIT 100
