WITH sales_agg AS (
    SELECT
        d_sale.d_year,
        d_sale.d_moy,
        i.i_category,
        sm.sm_ship_mode_id,
        cc.cc_name,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        SUM(cs.cs_quantity) AS total_sales_quantity,
        SUM(cs.cs_ext_discount_amt) AS total_discount_amount
    FROM catalog_sales cs
    JOIN date_dim d_sale ON cs.cs_sold_date_sk = d_sale.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d_sale.d_date >= DATE '2000-01-01' AND d_sale.d_date <= DATE '2002-12-31'
    GROUP BY d_sale.d_year, d_sale.d_moy, i.i_category, sm.sm_ship_mode_id, cc.cc_name
),
returns_agg AS (
    SELECT
        d_ret.d_year,
        d_ret.d_moy,
        i.i_category,
        sm.sm_ship_mode_id,
        cc.cc_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d_ret.d_date >= DATE '2000-01-01' AND d_ret.d_date <= DATE '2002-12-31'
    GROUP BY d_ret.d_year, d_ret.d_moy, i.i_category, sm.sm_ship_mode_id, cc.cc_name
)
SELECT
    s.d_year,
    s.d_moy,
    s.i_category,
    s.sm_ship_mode_id,
    s.cc_name,
    s.total_sales_amount,
    s.total_sales_quantity,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    CASE WHEN s.total_sales_quantity > 0 THEN (COALESCE(r.total_return_quantity, 0) * 1.0 / s.total_sales_quantity) ELSE 0 END AS return_quantity_rate,
    CASE WHEN s.total_sales_amount > 0 THEN (COALESCE(r.total_return_amount, 0) * 1.0 / s.total_sales_amount) ELSE 0 END AS return_amount_rate,
    CASE WHEN s.total_sales_quantity > 0 THEN (s.total_discount_amount * 1.0 / s.total_sales_quantity) ELSE 0 END AS avg_discount_per_item
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
    AND s.d_moy = r.d_moy
    AND s.i_category = r.i_category
    AND s.sm_ship_mode_id = r.sm_ship_mode_id
    AND s.cc_name = r.cc_name
ORDER BY s.d_year, s.d_moy, s.i_category, s.sm_ship_mode_id, s.cc_name
