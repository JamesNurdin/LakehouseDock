WITH base AS (
    SELECT
        d_sold.d_year AS year,
        w.w_state,
        i.i_category,
        p.p_promo_name,
        cc.cc_name,
        r.r_reason_desc,
        cs.cs_net_paid,
        ws.ws_net_paid,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        cs.cs_order_number,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_fy_year IN (1905, 1906)
      AND d_sold.d_moy = 6
      AND w.w_country = 'United States'
      AND cc.cc_tax_percentage = 0.03
      AND p.p_discount_active = 'Y'
      AND i.i_current_price > 100
),
agg AS (
    SELECT
        year,
        w_state,
        i_category,
        p_promo_name,
        cc_name,
        r_reason_desc,
        SUM(cs_net_paid) AS total_catalog_sales,
        SUM(ws_net_paid) AS total_web_sales,
        SUM(cr_return_amount) AS total_returns,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        AVG(cs_quantity) AS avg_catalog_qty
    FROM base
    GROUP BY
        year,
        w_state,
        i_category,
        p_promo_name,
        cc_name,
        r_reason_desc
)
SELECT
    *,
    RANK() OVER (PARTITION BY year ORDER BY total_catalog_sales DESC) AS sales_rank,
    SUM(total_catalog_sales) OVER (PARTITION BY year) AS year_total_catalog_sales
FROM agg
ORDER BY total_catalog_sales DESC
LIMIT 100
