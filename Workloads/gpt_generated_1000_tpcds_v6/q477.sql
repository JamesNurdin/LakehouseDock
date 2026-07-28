/*
Goal: Produce a multi‑source revenue and profit analysis per item category and brand, integrating store sales, web sales and catalog returns. The query demonstrates complex joins across all 13 TPC‑DS tables, applies several filters, uses a pre‑aggregation CTE (inventory), incorporates a scalar subquery, an EXISTS subquery, a window function, UNION ALL set operation, GROUPING SETS for subtotals, ordering and a LIMIT.
*/
WITH inv_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_warehouse_sk = 4
    GROUP BY inv_item_sk
),
store_side AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        SUM(ss.ss_ext_sales_price) AS revenue,
        SUM(ss.ss_net_profit)      AS profit,
        SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS return_amount,
        SUM(COALESCE(sr.sr_net_loss, 0))          AS return_loss,
        CAST(NULL AS decimal(7,2))                AS ship_cost,
        CAST(NULL AS decimal(7,2))                AS loss,
        inv_agg.total_qty_on_hand,
        ss.ss_sold_time_sk AS sold_time_sk
    FROM store_sales ss
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN item i                ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca   ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = i.i_item_sk
    JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
    WHERE i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND ca.ca_state = 'CA'
      AND cd.cd_education_status = 'College'
    GROUP BY i.i_item_sk, i.i_category, i.i_brand, s.s_store_sk, s.s_state,
             ss.ss_sold_time_sk, inv_agg.total_qty_on_hand
),
web_side AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        SUM(ws.ws_ext_sales_price) AS revenue,
        SUM(ws.ws_net_profit)      AS profit,
        CAST(NULL AS decimal(7,2)) AS return_amount,
        CAST(NULL AS decimal(7,2)) AS return_loss,
        SUM(COALESCE(ws.ws_ext_ship_cost, 0)) AS ship_cost,
        CAST(NULL AS decimal(7,2)) AS loss,
        inv_agg.total_qty_on_hand,
        ws.ws_sold_time_sk AS sold_time_sk
    FROM web_sales ws
    JOIN item i                 ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp            ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm           ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca    ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
    WHERE i.i_brand = 'Brand#12'
      AND sm.sm_type = 'AIR'
      AND ca.ca_state = 'CA'
      AND cd.cd_education_status = 'College'
    GROUP BY i.i_item_sk, i.i_category, i.i_brand,
             wp.wp_web_page_id, ws.ws_sold_time_sk, sm.sm_type,
             inv_agg.total_qty_on_hand
),
cat_side AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        SUM(cr.cr_return_amt_inc_tax) AS revenue,
        CAST(NULL AS decimal(7,2))   AS profit,
        CAST(NULL AS decimal(7,2))   AS return_amount,
        CAST(NULL AS decimal(7,2))   AS return_loss,
        CAST(NULL AS decimal(7,2))   AS ship_cost,
        SUM(cr.cr_net_loss)           AS loss,
        inv_agg.total_qty_on_hand,
        cr.cr_returned_time_sk AS sold_time_sk
    FROM catalog_returns cr
    JOIN item i               ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm         ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
    WHERE i.i_brand = 'Brand#12'
      AND sm.sm_type = 'AIR'
      AND ca.ca_state = 'CA'
      AND cd.cd_education_status = 'College'
    GROUP BY i.i_item_sk, i.i_category, i.i_brand,
             cr.cr_returned_time_sk, sm.sm_type, ca.ca_state,
             cd.cd_education_status, inv_agg.total_qty_on_hand
),
combined AS (
    SELECT i_item_sk, i_category, i_brand, revenue, profit, return_amount,
           return_loss, ship_cost, loss, total_qty_on_hand, sold_time_sk
    FROM store_side
    UNION ALL
    SELECT i_item_sk, i_category, i_brand, revenue, profit, return_amount,
           return_loss, ship_cost, loss, total_qty_on_hand, sold_time_sk
    FROM web_side
    UNION ALL
    SELECT i_item_sk, i_category, i_brand, revenue, profit, return_amount,
           return_loss, ship_cost, loss, total_qty_on_hand, sold_time_sk
    FROM cat_side
)
SELECT
    category,
    brand,
    SUM(revenue)        AS total_revenue,
    SUM(profit)         AS total_profit,
    SUM(loss)           AS total_loss,
    SUM(return_amount)  AS total_return_amount,
    SUM(return_loss)    AS total_return_loss,
    SUM(ship_cost)      AS total_ship_cost,
    SUM(total_qty_on_hand) AS total_qty_on_hand,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(revenue) DESC) AS revenue_rank,
    (SELECT COUNT(DISTINCT i_item_sk) FROM item) AS total_distinct_items
FROM (
    SELECT
        i_category AS category,
        i_brand    AS brand,
        i_item_sk,
        revenue,
        profit,
        loss,
        return_amount,
        return_loss,
        ship_cost,
        total_qty_on_hand,
        sold_time_sk
    FROM combined
) AS c
JOIN time_dim td ON c.sold_time_sk = td.t_time_sk
WHERE td.t_hour = 12
  AND EXISTS (SELECT 1 FROM catalog_returns cr2 WHERE cr2.cr_item_sk = c.i_item_sk)
GROUP BY GROUPING SETS ( (category, brand), (category), () )
ORDER BY total_revenue DESC
LIMIT 100
