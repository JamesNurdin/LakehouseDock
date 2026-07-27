WITH
    inv_agg AS (
        SELECT
            i.i_item_sk,
            i.i_product_name,
            d.d_year,
            SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory inv
        JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk, i.i_product_name, d.d_year
    ),
    promo_agg AS (
        SELECT
            i.i_item_sk,
            p.p_promo_id,
            d_start.d_year AS start_year,
            d_end.d_year AS end_year,
            SUM(p.p_cost) AS total_promo_cost
        FROM promotion p
        JOIN item i ON p.p_item_sk = i.i_item_sk
        JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
        JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
        GROUP BY i.i_item_sk, p.p_promo_id, d_start.d_year, d_end.d_year
    ),
    store_part AS (
        SELECT
            i.i_item_sk,
            i.i_product_name,
            d.d_year,
            inv_agg.total_qty_on_hand,
            SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
            promo_agg.total_promo_cost,
            r.r_reason_desc
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN inv_agg ON inv_agg.i_item_sk = i.i_item_sk AND inv_agg.d_year = d.d_year
        LEFT JOIN promo_agg ON promo_agg.i_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk, i.i_product_name, d.d_year,
                 inv_agg.total_qty_on_hand, promo_agg.total_promo_cost, r.r_reason_desc
    ),
    catalog_part AS (
        SELECT
            i.i_item_sk,
            i.i_product_name,
            d.d_year,
            inv_agg.total_qty_on_hand,
            SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
            promo_agg.total_promo_cost,
            r.r_reason_desc
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN inv_agg ON inv_agg.i_item_sk = i.i_item_sk AND inv_agg.d_year = d.d_year
        LEFT JOIN promo_agg ON promo_agg.i_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk, i.i_product_name, d.d_year,
                 inv_agg.total_qty_on_hand, promo_agg.total_promo_cost, r.r_reason_desc
    ),
    web_part AS (
        SELECT
            i.i_item_sk,
            i.i_product_name,
            d.d_year,
            inv_agg.total_qty_on_hand,
            SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
            promo_agg.total_promo_cost,
            r.r_reason_desc
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        LEFT JOIN inv_agg ON inv_agg.i_item_sk = i.i_item_sk AND inv_agg.d_year = d.d_year
        LEFT JOIN promo_agg ON promo_agg.i_item_sk = i.i_item_sk
        GROUP BY i.i_item_sk, i.i_product_name, d.d_year,
                 inv_agg.total_qty_on_hand, promo_agg.total_promo_cost, r.r_reason_desc
    ),
    combined_returns AS (
        SELECT * FROM store_part
        UNION ALL
        SELECT * FROM catalog_part
        UNION ALL
        SELECT * FROM web_part
    )
SELECT
    i_item_sk,
    i_product_name,
    d_year,
    SUM(total_qty_on_hand) AS agg_qty_on_hand,
    SUM(total_return_amount) AS agg_return_amount,
    SUM(total_promo_cost) AS agg_promo_cost,
    r_reason_desc
FROM combined_returns
GROUP BY i_item_sk, i_product_name, d_year, r_reason_desc
HAVING SUM(total_return_amount) > 1000
ORDER BY agg_return_amount DESC
LIMIT 100
