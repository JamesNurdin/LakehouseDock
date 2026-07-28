WITH base AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(sr.sr_return_amt) AS total_returns
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'OVERNIGHT'
      AND p.p_discount_active = 'Y'
      AND s.s_state = 'CA'
      AND cs.cs_quantity > 5
    GROUP BY s.s_store_id, s.s_store_name, d.d_year
)
SELECT
    s_store_id,
    s_store_name,
    d_year,
    catalog_net_paid,
    web_net_paid,
    total_returns,
    catalog_net_paid + web_net_paid - total_returns AS net_revenue,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (catalog_net_paid + web_net_paid - total_returns) DESC) AS revenue_rank
FROM base
ORDER BY revenue_rank
LIMIT 100
