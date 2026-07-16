SELECT
    t.s_store_id,
    t.s_store_name,
    t.s_city,
    t.s_state,
    t.d_year,
    t.i_category,
    t.i_brand,
    t.return_transactions,
    t.total_return_amount,
    t.total_net_loss,
    t.total_fee,
    t.total_return_tax,
    t.total_ship_cost,
    t.avg_return_quantity,
    t.avg_refunded_income_band,
    t.avg_returning_income_band,
    ROW_NUMBER() OVER (PARTITION BY t.d_year ORDER BY t.total_net_loss DESC) AS store_year_rank
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year,
        i.i_category,
        i.i_brand,
        COUNT(*) AS return_transactions,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_return_tax) AS total_return_tax,
        SUM(cr.cr_return_ship_cost) AS total_ship_cost,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        AVG(hd_refunded.hd_income_band_sk) AS avg_refunded_income_band,
        AVG(hd_returning.hd_income_band_sk) AS avg_returning_income_band
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND i.i_category IS NOT NULL
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year,
        i.i_category,
        i.i_brand
) t
ORDER BY
    t.d_year,
    t.total_net_loss DESC,
    t.s_store_id
