/* Goal: Identify customers with the highest net loss from store returns, enriched with their catalog and web return activity, inventory levels, and demographic income band information, to pinpoint high‑loss customer segments. */

WITH sr_agg AS (
    SELECT
        sr_customer_sk,
        SUM(sr_net_loss) AS total_sr_net_loss,
        COUNT(*) AS sr_return_cnt
    FROM store_returns
    GROUP BY sr_customer_sk
),
agg_data AS (
    SELECT
        cust.c_customer_id,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cp.cp_department,
        w.w_warehouse_name,
        SUM(COALESCE(inv_inner.inv_quantity_on_hand, 0)) AS total_inventory_qty,
        sr_agg.total_sr_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
        SUM(CASE WHEN cr.cr_return_amount > 0 THEN cr.cr_return_amount ELSE 0 END) AS total_catalog_return_amount,
        SUM(CASE WHEN wr.wr_return_amt > 0 THEN wr.wr_return_amt ELSE 0 END) AS total_web_return_amount
    FROM sr_agg
    JOIN customer cust
        ON sr_agg.sr_customer_sk = cust.c_customer_sk
    JOIN household_demographics hd
        ON cust.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr
        ON cust.c_customer_sk = cr.cr_returning_customer_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv_inner
        ON w.w_warehouse_sk = inv_inner.inv_warehouse_sk
    JOIN web_returns wr
        ON cust.c_customer_sk = wr.wr_returning_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    FULL OUTER JOIN inventory inv_full
        ON w.w_warehouse_sk = inv_full.inv_warehouse_sk
    WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = cust.c_customer_sk
          AND cr2.cr_return_amount > 50
    )
    GROUP BY
        cust.c_customer_id,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cp.cp_department,
        w.w_warehouse_name,
        sr_agg.total_sr_net_loss
    HAVING SUM(CASE WHEN cr.cr_return_amount > 0 THEN cr.cr_return_amount ELSE 0 END) > 1000
)
SELECT
    c_customer_id,
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    cp_department,
    w_warehouse_name,
    total_inventory_qty,
    total_sr_net_loss,
    distinct_catalog_orders,
    total_catalog_return_amount,
    total_web_return_amount,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY total_sr_net_loss DESC) AS customer_rank_by_sr_loss
FROM agg_data
ORDER BY total_sr_net_loss DESC
LIMIT 100
