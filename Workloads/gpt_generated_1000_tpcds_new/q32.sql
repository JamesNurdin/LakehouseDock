/*
Goal: Identify the top‑performing stores by total net profit per year, ranking them within each state, while demonstrating a comprehensive join across all 13 TPC‑DS tables, applying multiple filters, an IN‑subquery filter, a HAVING clause, and a window‑function rank.
*/
WITH base AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        ss.ss_net_profit,
        i.i_current_price,
        ib.ib_upper_bound,
        cc.cc_tax_percentage,
        wp.wp_type,
        sr.sr_return_quantity,
        inv.inv_quantity_on_hand,
        c.c_customer_sk
    FROM store_sales ss
    JOIN date_dim d                     ON ss.ss_sold_date_sk   = d.d_date_sk
    JOIN store s                        ON ss.ss_store_sk      = s.s_store_sk
    JOIN customer c                     ON ss.ss_customer_sk   = c.c_customer_sk
    JOIN household_demographics hd      ON ss.ss_hdemo_sk      = hd.hd_demo_sk
    JOIN income_band ib                 ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i                         ON ss.ss_item_sk       = i.i_item_sk
    JOIN promotion p                    ON ss.ss_promo_sk      = p.p_promo_sk
    JOIN store_returns sr               ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN inventory inv                  ON inv.inv_item_sk = i.i_item_sk
                                      AND inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w                    ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc                 ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN web_page wp                    ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_current_price > 50
      AND s.s_state IN ('CA', 'TX', 'NY')
      AND ib.ib_upper_bound >= 80000
      AND cc.cc_tax_percentage < 8.0
      AND s.s_store_sk IN (
            SELECT ss_store_sk FROM store_sales WHERE ss_quantity > 5
        )
)
SELECT
    store_id,
    store_name,
    state,
    year,
    SUM(ss_net_profit)               AS total_net_profit,
    SUM(inv_quantity_on_hand)        AS total_on_hand,
    COUNT(DISTINCT customer_sk)      AS distinct_customers,
    RANK() OVER (PARTITION BY state ORDER BY SUM(ss_net_profit) DESC) AS profit_rank_state
FROM (
    SELECT
        s_store_id      AS store_id,
        s_store_name    AS store_name,
        s_state         AS state,
        d_year          AS year,
        ss_net_profit,
        inv_quantity_on_hand,
        c_customer_sk   AS customer_sk
    FROM base
) t
GROUP BY store_id, store_name, state, year
HAVING SUM(ss_net_profit) > 10000
ORDER BY state, profit_rank_state, total_net_profit DESC
