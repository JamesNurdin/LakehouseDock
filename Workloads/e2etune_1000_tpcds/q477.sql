WITH cc_agg AS (
    SELECT
        cc.cc_mkt_id,
        cc.cc_state,
        COUNT(*) AS num_call_centers,
        AVG(cc.cc_employees) AS avg_employees,
        SUM(cc.cc_sq_ft) AS total_sq_ft,
        AVG(cc.cc_tax_percentage) AS avg_tax_pct
    FROM call_center cc
    WHERE cc.cc_rec_end_date >= DATE '2000-01-01'
      AND cc.cc_gmt_offset BETWEEN -8.00 AND -5.00
    GROUP BY cc.cc_mkt_id, cc.cc_state
),
item_agg AS (
    SELECT
        i.i_category_id,
        i.i_brand,
        COUNT(*) AS num_items,
        AVG(i.i_current_price) AS avg_price,
        AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
        SUM(i.i_current_price) AS total_price
    FROM item i
    WHERE i.i_rec_end_date IS NULL OR i.i_rec_end_date > DATE '2020-01-01'
    GROUP BY i.i_category_id, i.i_brand
)
SELECT
    cc.cc_state,
    i.i_brand,
    cc.num_call_centers,
    cc.avg_employees,
    cc.total_sq_ft,
    cc.avg_tax_pct,
    i.num_items,
    i.avg_price,
    i.avg_wholesale_cost,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY cc.total_sq_ft DESC) AS state_sqft_rank
FROM cc_agg cc
JOIN item_agg i
    ON cc.cc_mkt_id = i.i_category_id
WHERE cc.total_sq_ft > 10000
ORDER BY cc.cc_state, state_sqft_rank
