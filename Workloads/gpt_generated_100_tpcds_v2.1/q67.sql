WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        ca.ca_state,
        d.d_year,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ws.ws_quantity) AS web_quantity
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c_ws
        ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    JOIN customer_address ca_ws
        ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    JOIN customer_demographics cd_ws
        ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
    JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2002
      AND cd.cd_marital_status = 'M'
      AND ca.ca_state = 'TX'
      AND p.p_discount_active = 'Y'
      AND ss.ss_quantity > 5
    GROUP BY c.c_customer_id, ca.ca_state, d.d_year
    HAVING SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) > 10000
)
SELECT
    c_customer_id,
    ca_state,
    d_year,
    store_net_paid,
    web_net_paid,
    (store_net_paid + web_net_paid) AS total_net_paid,
    ROW_NUMBER() OVER (ORDER BY (store_net_paid + web_net_paid) DESC) AS revenue_rank
FROM sales_agg
ORDER BY revenue_rank
LIMIT 100
