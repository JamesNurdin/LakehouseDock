WITH base AS (
    SELECT
        s.s_store_id,
        i.i_category,
        cs.cs_net_profit,
        cr.cr_net_loss,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand,
        p.p_cost,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd_bill.hd_vehicle_count
    FROM catalog_sales cs
    JOIN date_dim ds
        ON cs.cs_sold_date_sk = ds.d_date_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
    LEFT JOIN date_dim ds_wr
        ON wr.wr_returned_date_sk = ds_wr.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = ds.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = ds.d_date_sk
    LEFT JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ds.d_year = 2001
      AND i.i_category = 'Sports'
      AND w.w_state = 'CA'
      AND r_cr.r_reason_desc = 'Damaged'
      AND hd_bill.hd_vehicle_count > 1
),
agg AS (
    SELECT
        s_store_id,
        i_category,
        COALESCE(SUM(cs_net_profit), 0) AS total_sales_profit,
        COALESCE(SUM(cr_net_loss), 0) AS total_return_loss,
        COALESCE(SUM(wr_net_loss), 0) AS total_web_return_loss,
        COALESCE(SUM(cs_net_profit), 0) - COALESCE(SUM(cr_net_loss), 0) - COALESCE(SUM(wr_net_loss), 0) AS net_profit,
        COALESCE(SUM(inv_quantity_on_hand), 0) AS total_inventory,
        COALESCE(SUM(p_cost), 0) AS total_promotion_cost,
        AVG(ib_lower_bound) AS avg_income_lower
    FROM base
    GROUP BY s_store_id, i_category
)
SELECT
    s_store_id,
    i_category,
    total_sales_profit,
    total_return_loss,
    total_web_return_loss,
    net_profit,
    total_inventory,
    total_promotion_cost,
    avg_income_lower,
    DENSE_RANK() OVER (PARTITION BY s_store_id ORDER BY net_profit DESC) AS category_rank
FROM agg
ORDER BY s_store_id, category_rank
LIMIT 100
