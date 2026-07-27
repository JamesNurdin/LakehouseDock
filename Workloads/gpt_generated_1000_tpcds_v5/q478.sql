WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        d_sold.d_year AS sold_year,
        sm.sm_type,
        cd.cd_gender,
        ca.ca_state,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        COUNT(*) AS order_cnt,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d_sold.d_year BETWEEN 2001 AND 2002
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cd.cd_gender = 'M'
      AND ca.ca_country = 'United States'
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_bill_customer_sk = cs.cs_bill_customer_sk
            AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
            AND ws.ws_net_paid > 1000
      )
    GROUP BY
        cc.cc_call_center_id,
        d_sold.d_year,
        sm.sm_type,
        cd.cd_gender,
        ca.ca_state
)
SELECT
    cc_call_center_id,
    sold_year,
    sm_type,
    cd_gender,
    ca_state,
    total_net_paid,
    order_cnt,
    avg_quantity,
    total_net_paid / NULLIF(order_cnt, 0) AS avg_net_per_order
FROM sales_agg
WHERE total_net_paid > 100000
ORDER BY total_net_paid DESC
LIMIT 100
