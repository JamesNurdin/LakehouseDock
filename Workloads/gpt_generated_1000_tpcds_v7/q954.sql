WITH return_stats AS (
    SELECT
        s.s_store_id AS store_id,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk AND wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 5.00
      AND c.c_birth_country = 'MEXICO'
      AND ib.ib_upper_bound >= 50000
      AND t.t_hour BETWEEN 9 AND 17
      AND cr.cr_return_quantity > 1
    GROUP BY s.s_store_id, d.d_year
),
store_agg AS (
    SELECT
        store_id,
        SUM(total_return_amount) AS store_total_return,
        SUM(total_return_qty) AS store_total_qty,
        SUM(return_cnt) AS store_return_cnt
    FROM return_stats
    GROUP BY store_id
)
SELECT
    store_id,
    store_total_return,
    store_total_qty,
    store_return_cnt,
    store_total_return / NULLIF(store_total_qty, 0) AS avg_return_amount_per_item
FROM store_agg
WHERE store_total_return > 2000
ORDER BY store_total_return DESC
LIMIT 100
