WITH joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_paid,
        c.c_customer_id,
        c.c_birth_month,
        cp.cp_department,
        cr.cr_return_amount,
        ws.ws_ext_tax,
        ws.ws_net_paid AS ws_net_paid,
        ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    WHERE cc.cc_rec_start_date >= DATE '2001-01-01'
      AND cp.cp_department IN ('Books', 'Electronics')
      AND cs.cs_quantity > 5
      AND cs.cs_sales_price > 100.00
      AND ws.ws_ext_tax > 50.00
      AND c.c_birth_month = 5
),
agg AS (
    SELECT
        c_customer_id,
        cp_department,
        SUM(cs_net_paid) AS total_cs_net_paid,
        SUM(cr_return_amount) AS total_cr_return_amount,
        SUM(ws_net_paid) AS total_ws_net_paid,
        AVG(cs_quantity) AS avg_quantity,
        MIN(cs_sales_price) AS min_sales_price,
        MAX(cs_sales_price) AS max_sales_price,
        COUNT(DISTINCT cs_order_number) AS cnt_orders,
        GROUPING(c_customer_id) AS g_customer,
        GROUPING(cp_department) AS g_department
    FROM joined
    GROUP BY GROUPING SETS (
        (c_customer_id, cp_department),
        (c_customer_id),
        (cp_department),
        ()
    )
)
SELECT
    c_customer_id,
    cp_department,
    total_cs_net_paid,
    total_cr_return_amount,
    total_ws_net_paid,
    avg_quantity,
    min_sales_price,
    max_sales_price,
    cnt_orders,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper_bound,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY total_cs_net_paid DESC) AS rn
FROM agg
WHERE g_customer = 0  -- keep rows with customer dimension present
ORDER BY total_cs_net_paid DESC, c_customer_id
LIMIT 100
