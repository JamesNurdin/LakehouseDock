WITH
    base_sales_promo AS (
        SELECT
            ss.ss_sold_date_sk AS sold_date_sk,
            ss.ss_item_sk     AS item_sk,
            ss.ss_store_sk    AS store_sk,
            ss.ss_customer_sk AS customer_sk,
            ss.ss_hdemo_sk    AS hdemo_sk,
            ss.ss_addr_sk     AS addr_sk,
            ss.ss_promo_sk    AS promo_sk,
            ss.ss_sales_price,
            ss.ss_net_profit,
            ss.ss_net_paid,
            p.p_promo_name,
            p.p_discount_active,
            p.p_start_date_sk,
            p.p_end_date_sk
        FROM
            store_sales ss
            FULL OUTER JOIN promotion p
                ON ss.ss_promo_sk = p.p_promo_sk
    ),
    joined_all AS (
        SELECT
            bsp.*,
            d.d_year,
            i.i_brand,
            i.i_category,
            i.i_current_price,
            ca.ca_state,
            hd.hd_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            s.s_store_name,
            s.s_state,
            w.w_warehouse_name,
            cp.cp_department,
            cc.cc_name,
            sm.sm_type               AS ship_mode_type,
            inv.inv_quantity_on_hand,
            wp.wp_type               AS web_page_type,
            wr.wr_return_quantity
        FROM base_sales_promo bsp
        JOIN date_dim d
            ON bsp.sold_date_sk = d.d_date_sk
        JOIN item i
            ON bsp.item_sk = i.i_item_sk
        LEFT JOIN customer_address ca
            ON bsp.addr_sk = ca.ca_address_sk
        LEFT JOIN household_demographics hd
            ON bsp.hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN store s
            ON bsp.store_sk = s.s_store_sk
        LEFT JOIN catalog_returns cr
            ON bsp.item_sk = cr.cr_item_sk
               AND bsp.sold_date_sk = cr.cr_returned_date_sk
        LEFT JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN warehouse w
            ON cr.cr_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
               AND inv.inv_warehouse_sk = w.w_warehouse_sk
               AND inv.inv_date_sk = d.d_date_sk
        LEFT JOIN web_page wp
            ON d.d_date_sk = wp.wp_creation_date_sk
        LEFT JOIN web_returns wr
            ON i.i_item_sk = wr.wr_item_sk
               AND d.d_date_sk = wr.wr_returned_date_sk
        WHERE
            d.d_year = 2001
            AND i.i_brand = 'Brand#12'
            AND s.s_state = 'CA'
            AND cp.cp_department = 'Sports'
            AND bsp.p_discount_active = 'Y'
            AND inv.inv_quantity_on_hand > 0
    ),
    ranked_sales AS (
        SELECT
            s_store_name,
            d_year,
            i_brand,
            SUM(ss_net_profit)                         AS total_profit,
            ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY SUM(ss_net_profit) DESC) AS profit_rank,
            COUNT(DISTINCT customer_sk)                AS distinct_customers
        FROM joined_all
        GROUP BY s_store_name, d_year, i_brand
    ),
    union_set AS (
        SELECT s_store_name, total_profit FROM ranked_sales WHERE profit_rank = 1
        UNION
        SELECT s_store_name, total_profit FROM ranked_sales WHERE profit_rank = 2
    ),
    except_customers AS (
        SELECT DISTINCT ss_customer_sk FROM store_sales
        EXCEPT
        SELECT DISTINCT wr_returning_customer_sk FROM web_returns
    )
SELECT
    u.s_store_name,
    u.total_profit,
    ec.distinct_customers
FROM union_set u
LEFT JOIN (
    SELECT COUNT(*) AS distinct_customers FROM except_customers
) ec ON true
ORDER BY u.total_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
