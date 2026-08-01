WITH
    -- Base join of all twelve tables (using only the permitted join keys)
    base AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_item_sk,
            cs.cs_warehouse_sk,
            cs.cs_ship_mode_sk,
            cs.cs_call_center_sk,
            cs.cs_bill_addr_sk,
            cs.cs_bill_cdemo_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_quantity,
            cs.cs_sales_price,
            cs.cs_net_profit,
            cs.cs_ext_sales_price,
            d.d_year,
            i.i_category,
            i.i_current_price,
            w.w_state,
            cc.cc_name,
            sm.sm_type,
            ca.ca_state,
            hd.hd_income_band_sk,
            sr.sr_return_quantity,
            inv.inv_quantity_on_hand,
            wp.wp_type,
            -- create a small array that we will later UNNEST
            ARRAY[cs.cs_quantity, COALESCE(sr.sr_return_quantity, 0)] AS qty_array
        FROM catalog_sales cs
        JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        JOIN customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN inventory inv
            ON inv.inv_item_sk = cs.cs_item_sk
           AND inv.inv_date_sk = cs.cs_sold_date_sk
        LEFT JOIN store_returns sr
            ON sr.sr_item_sk = cs.cs_item_sk
           AND sr.sr_returned_date_sk = cs.cs_sold_date_sk
        LEFT JOIN web_page wp
            ON wp.wp_creation_date_sk = cs.cs_sold_date_sk
        WHERE d.d_year = 2001                         -- predicate 1
          AND i.i_current_price > 20                  -- predicate 2
          AND ca.ca_state = 'CA'                      -- predicate 3
          AND sm.sm_type = 'AIR'                      -- predicate 4
    ),
    -- Aggregate per item
    agg AS (
        SELECT
            cs_item_sk,
            i_category,
            w_state,
            d_year,
            cc_name,
            SUM(cs_net_profit)      AS total_profit,
            SUM(cs_ext_sales_price) AS total_sales,
            AVG(cs_sales_price)     AS avg_price,
            COUNT(*)                AS order_cnt,
            MAX(qty_array)          AS max_qty_array,
            MIN(qty_array)          AS min_qty_array
        FROM base
        GROUP BY cs_item_sk, i_category, w_state, d_year, cc_name
        HAVING SUM(cs_net_profit) > 1000               -- HAVING clause
    ),
    -- Window ranking inside each category
    ranked AS (
        SELECT
            a.*, 
            ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_profit DESC) AS rank_in_cat
        FROM agg a
    ),
    -- Keep rows that have at least one matching return (correlated EXISTS)
    filtered_exists AS (
        SELECT r.*
        FROM ranked r
        WHERE EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_item_sk = r.cs_item_sk
              AND sr.sr_return_quantity > 0
        )
    ),
    -- Expand the array created in the base CTE (UNNEST) – this introduces a row per element
    unnest_expanded AS (
        SELECT
            f.*, 
            q AS expanded_qty
        FROM filtered_exists f
        CROSS JOIN UNNEST(f.max_qty_array) AS t(q)
    ),
    -- Two alternative selections that will be UNION‑ed
    select_a AS (
        SELECT cs_item_sk, total_profit, rank_in_cat
        FROM unnest_expanded
        WHERE rank_in_cat <= 5
    ),
    select_b AS (
        SELECT cs_item_sk, total_profit, rank_in_cat
        FROM unnest_expanded
        WHERE rank_in_cat > 5
    ),
    union_set AS (
        SELECT cs_item_sk, total_profit FROM select_a
        UNION
        SELECT cs_item_sk, total_profit FROM select_b
    ),
    -- Subtract a set of low‑profit items
    except_set AS (
        SELECT cs_item_sk FROM union_set
        EXCEPT
        SELECT cs_item_sk FROM unnest_expanded WHERE total_profit < 2000
    ),
    -- Intersect with a set of high‑average‑price items
    intersect_set AS (
        SELECT cs_item_sk FROM union_set
        INTERSECT
        SELECT cs_item_sk FROM unnest_expanded WHERE avg_price > 50
    ),
    -- Final set: keep items that survive the EXCEPT and are present in the INTERSECT
    final_set AS (
        SELECT u.cs_item_sk, u.total_profit
        FROM union_set u
        WHERE u.cs_item_sk IN (SELECT cs_item_sk FROM intersect_set)
          AND u.cs_item_sk NOT IN (SELECT cs_item_sk FROM except_set)
    )
SELECT
    f.cs_item_sk,
    i.i_item_id,
    i.i_product_name,
    f.total_profit
FROM final_set f
JOIN item i ON f.cs_item_sk = i.i_item_sk
ORDER BY f.total_profit DESC
LIMIT 100
