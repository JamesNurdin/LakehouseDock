WITH sales_part AS (
    SELECT
        i.i_category AS category,
        s.s_state   AS state,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date >= DATE '2020-01-01'
      AND i.i_rec_end_date <= DATE '2025-12-31'
      AND i.i_current_price > 30
      AND i.i_category = 'Sports'
      AND p.p_discount_active = 'Y'
      AND p.p_cost < 50
      AND sm.sm_type = 'AIR'
      AND inv.inv_quantity_on_hand > 0
      AND r.r_reason_desc LIKE '%damaged%'
      AND sr.sr_return_amt > 0
      AND cs.cs_quantity > 5
    GROUP BY i.i_category, s.s_state
),
web_part AS (
    SELECT
        i.i_category AS category,
        CAST(NULL AS varchar) AS state,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE i.i_current_price > 30
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND ws.ws_quantity > 2
    GROUP BY i.i_category
)
SELECT
    category,
    state,
    SUM(sales_amount) AS total_sales,
    SUM(order_cnt)   AS total_orders,
    CASE WHEN SUM(sales_amount) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_level
FROM (
    SELECT * FROM sales_part
    UNION ALL
    SELECT * FROM web_part
) u
GROUP BY ROLLUP (category, state)
HAVING SUM(sales_amount) > 0
ORDER BY total_sales DESC
LIMIT 100
