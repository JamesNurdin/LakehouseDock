/* goal: Analyze sales and return performance by product category and customer gender, including inventory levels, promotion details, and shipping carrier, while showing subtotals and a running total per category */
WITH base AS (
    SELECT
        i.i_category,
        cd.cd_gender,
        cs.cs_ext_sales_price        AS cs_sales,
        cs.cs_net_profit             AS cs_profit,
        cr.cr_return_amount          AS cr_return,
        sr.sr_return_amt             AS sr_return,
        inv.inv_quantity_on_hand     AS inv_qty,
        sm.sm_carrier                AS ship_carrier,
        p.p_discount_active          AS promo_active,
        w.w_warehouse_name           AS warehouse_name
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk      = cs.cs_item_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
       AND p.p_item_sk    = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
       AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
       AND cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_item_sk      = i.i_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store_returns sr
        ON sr.sr_item_sk      = i.i_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    WHERE cs.cs_sold_date_sk BETWEEN 2452000 AND 2453000
      AND w.w_state = 'CA'
      AND sm.sm_carrier = 'FEDEX'
),
agg AS (
    SELECT
        i_category,
        cd_gender,
        SUM(cs_sales)    AS total_sales,
        SUM(cs_profit)   AS total_profit,
        SUM(cr_return)   AS total_catalog_returns,
        SUM(sr_return)   AS total_store_returns,
        SUM(inv_qty)     AS total_inventory,
        COUNT(*)         AS txn_count
    FROM base
    GROUP BY ROLLUP(i_category, cd_gender)
)
SELECT
    i_category,
    cd_gender,
    total_sales,
    total_profit,
    total_catalog_returns,
    total_store_returns,
    total_inventory,
    txn_count,
    /* scalar subquery: overall average profit across all groups */
    (SELECT AVG(total_profit) FROM agg) AS overall_avg_profit,
    /* window function: running total of sales per category */
    SUM(total_sales) OVER (PARTITION BY i_category ORDER BY cd_gender ROWS UNBOUNDED PRECEDING) AS category_sales_running_total
FROM agg
WHERE total_sales > 10000
  AND txn_count > 5
  AND total_inventory > 0
ORDER BY i_category NULLS FIRST, cd_gender
LIMIT 100
