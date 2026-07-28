/*
Goal: Analyse promotional performance by reason for catalog returns, focusing on positive overall profit periods in 2001 Q1, high inventory levels, and ranking promotions by total profit.
The query joins all selected TPC‑DS tables using only the permitted join keys, aggregates return and sales metrics in a CTE, applies additional filters with a scalar subquery, uses a CASE expression to flag profit direction, and adds window functions for average profit per promotion and ranking.
*/
WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        d_cr.d_year AS return_year,
        cr.cr_return_amount,
        cr.cr_net_loss,
        r.r_reason_desc,
        sm.sm_type AS return_ship_type,
        w.w_warehouse_name,
        inv.inv_quantity_on_hand,
        ss.ss_net_profit AS store_profit,
        ws.ws_net_profit AS web_profit,
        p.p_promo_id,
        CASE
            WHEN ss.ss_net_profit + ws.ws_net_profit > 0 THEN 'POSITIVE'
            ELSE 'NEGATIVE'
        END AS profit_flag
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c_returning.c_customer_sk
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk AND inv.inv_date_sk = d_ss.d_date_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c_refunded.c_customer_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN date_dim d_ws_open ON web.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close ON web.web_close_date_sk = d_ws_close.d_date_sk
    WHERE d_cr.d_year = 2001                 -- filter 1: only returns from 2001
      AND d_ss.d_moy BETWEEN 1 AND 3         -- filter 2: store sales in Jan‑Mar
      AND inv.inv_quantity_on_hand > 100    -- filter 3: inventory threshold
),
agg1 AS (
    SELECT
        p_promo_id,
        r_reason_desc,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(cr_net_loss) AS sum_net_loss,
        SUM(store_profit) AS sum_store_profit,
        SUM(web_profit) AS sum_web_profit,
        SUM(inv_quantity_on_hand) AS sum_inventory,
        profit_flag
    FROM base
    GROUP BY p_promo_id, r_reason_desc, profit_flag
),
final AS (
    SELECT
        p_promo_id,
        r_reason_desc,
        sum_return_amount,
        sum_net_loss,
        sum_store_profit,
        sum_web_profit,
        sum_inventory,
        profit_flag,
        (sum_store_profit + sum_web_profit) AS total_profit,
        AVG(sum_store_profit + sum_web_profit) OVER (PARTITION BY p_promo_id) AS avg_profit_per_promo,
        RANK() OVER (ORDER BY (sum_store_profit + sum_web_profit) DESC) AS profit_rank
    FROM agg1
    WHERE profit_flag = 'POSITIVE'
      AND sum_return_amount > (
            SELECT AVG(cr_return_amount)
            FROM catalog_returns
            WHERE cr_returned_date_sk IN (
                SELECT d_date_sk FROM date_dim WHERE d_year = 2001
            )
        )
)
SELECT
    p_promo_id,
    r_reason_desc,
    sum_return_amount,
    sum_net_loss,
    total_profit,
    avg_profit_per_promo,
    profit_rank
FROM final
ORDER BY profit_rank
LIMIT 100
