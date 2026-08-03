WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        d.d_year,
        d.d_date,
        ca.ca_state,
        dm.cd_credit_rating,
        pm.p_promo_name,
        sm.sm_type,
        cc.cc_name,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        s.s_state AS store_state,
        cr.cr_return_amount,
        cr.cr_fee,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics dm ON c.c_current_cdemo_sk = dm.cd_demo_sk
    JOIN promotion pm ON cs.cs_promo_sk = pm.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND cs.cs_quantity > 5
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
            AND cr2.cr_return_amount > 150.00
      )
),
aggregated_sales AS (
    SELECT
        d_year,
        ca_state,
        SUM(cs_net_paid) AS total_net_paid,
        COUNT(*) AS txn_cnt,
        CASE WHEN SUM(cs_net_paid) > 100000 THEN 'High' ELSE 'Medium' END AS revenue_bucket
    FROM sales_base
    GROUP BY d_year, ca_state
    UNION
    SELECT
        d_year,
        ca_state,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(*) AS txn_cnt,
        CASE WHEN SUM(ws_net_paid) > 100000 THEN 'High' ELSE 'Medium' END AS revenue_bucket
    FROM sales_base
    WHERE ws_quantity IS NOT NULL
    GROUP BY d_year, ca_state
)
SELECT
    d_year,
    ca_state,
    SUM(total_net_paid) AS grand_total_net_paid,
    SUM(txn_cnt) AS total_transactions,
    MAX(revenue_bucket) AS max_revenue_bucket
FROM aggregated_sales
GROUP BY d_year, ca_state
ORDER BY grand_total_net_paid DESC
LIMIT 100
