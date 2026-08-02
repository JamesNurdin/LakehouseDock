WITH
    promo_agg AS (
        SELECT
            p.p_item_sk AS item_sk,
            sum(p.p_cost) AS total_promo_cost,
            count(*) AS promo_count,
            array_agg(p.p_cost) AS promo_costs_arr
        FROM promotion p
        JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
        JOIN date_dim d_end   ON p.p_end_date_sk = d_end.d_date_sk
        WHERE d_start.d_year = 2001
          AND d_end.d_year   = 2001
        GROUP BY p.p_item_sk
    ),
    promo_costs AS (
        SELECT
            pa.item_sk,
            cost_elem
        FROM promo_agg pa
        CROSS JOIN UNNEST(pa.promo_costs_arr) AS t(cost_elem)
    ),
    intersect_items AS (
        SELECT cr.cr_item_sk AS item_sk
        FROM catalog_returns cr
        WHERE cr.cr_return_quantity > 0
        INTERSECT
        SELECT p.p_item_sk
        FROM promotion p
        WHERE p.p_cost > 200
    )
SELECT
    dr.d_year,
    i.i_category,
    i.i_brand,
    MIN(dr.d_date) AS min_return_date,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    AVG(cr.cr_return_amount)   AS avg_return_amt,
    SUM(promo_agg.total_promo_cost) AS total_promo_cost,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages,
    MAX(cr.cr_net_loss) AS max_net_loss,
    s.s_store_name,
    wp.wp_url,
    cd.cd_gender,
    hd.hd_buy_potential,
    inc.ib_lower_bound,
    inc.ib_upper_bound,
    pc.cost_elem AS promo_cost_element
FROM catalog_returns cr
JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band inc ON hd.hd_income_band_sk = inc.ib_income_band_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim dcp ON cp.cp_start_date_sk = dcp.d_date_sk
JOIN store s ON s.s_closed_date_sk = dr.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = dr.d_date_sk
JOIN promo_agg ON i.i_item_sk = promo_agg.item_sk
JOIN promo_costs pc ON i.i_item_sk = pc.item_sk
JOIN intersect_items ii ON i.i_item_sk = ii.item_sk
WHERE dr.d_year = 2001
  AND i.i_category = 'Shoes'
  AND s.s_state = 'CA'
  AND NOT EXISTS (
        SELECT 1
        FROM promotion p_ex
        WHERE p_ex.p_item_sk = i.i_item_sk
          AND p_ex.p_cost > 1000
    )
GROUP BY
    dr.d_year,
    i.i_category,
    i.i_brand,
    s.s_store_name,
    wp.wp_url,
    cd.cd_gender,
    hd.hd_buy_potential,
    inc.ib_lower_bound,
    inc.ib_upper_bound,
    pc.cost_elem
ORDER BY total_return_qty DESC, dr.d_year
LIMIT 100
