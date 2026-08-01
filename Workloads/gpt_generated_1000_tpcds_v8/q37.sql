/*
Goal: Compute yearly net sales by warehouse state and ship mode, including total sales, returns, distinct order count, and the proportion of sales that were discounted. The query joins all 16 TPC‑DS tables, applies multiple filters, uses a CASE expression, a DISTINCT count, an EXISTS semi‑join, and orders the final results.
*/
WITH base_join AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cr.cr_return_amount,
        ss.ss_ticket_number,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid,
        sr.sr_return_quantity AS sr_return_quantity,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        wr.wr_return_quantity,
        i.i_current_price,
        p.p_discount_active,
        d.d_year,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        w.w_country,
        w.w_state,
        sm.sm_type,
        inv.inv_quantity_on_hand,
        wp.wp_type
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = cs.cs_item_sk
       AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = cs.cs_item_sk
       AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_date_sk = d.d_date_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 1998 AND 1999
      AND w.w_country = 'United States'
      AND i.i_color = 'Red'
      AND ib.ib_lower_bound > 50000
      AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = cs.cs_promo_sk
              AND p2.p_discount_active = 'Y'
          )
),
agg1 AS (
    SELECT
        d_year,
        w_state,
        sm_type,
        SUM(cs_net_paid) AS total_sales,
        SUM(COALESCE(cr_return_amount, 0)) AS total_returns,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        SUM(CASE WHEN p_discount_active = 'Y' THEN cs_net_paid ELSE 0 END) AS discounted_sales
    FROM base_join
    GROUP BY d_year, w_state, sm_type
)
SELECT
    d_year,
    w_state,
    sm_type,
    total_sales,
    total_returns,
    distinct_orders,
    discounted_sales,
    (total_sales - total_returns) AS net_sales,
    CASE WHEN total_sales > 0 THEN discounted_sales / total_sales ELSE 0 END AS discount_rate
FROM agg1
WHERE (total_sales - total_returns) > 10000
ORDER BY net_sales DESC
LIMIT 100
