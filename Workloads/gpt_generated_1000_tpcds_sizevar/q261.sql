WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        COUNT(*) AS sales_txn_cnt,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_profit) AS avg_profit,
        SUM(CASE WHEN ss_quantity > 5 THEN ss_ext_sales_price ELSE 0 END) AS high_qty_sales
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_store_sk, ss_sold_date_sk
)
SELECT
    s.s_store_name,
    d.d_year,
    COUNT(DISTINCT cr.cr_order_number) AS return_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ss_agg.total_sales) AS total_sales,
    AVG(ss_agg.avg_profit) AS avg_profit_per_store,
    SUM(ss_agg.high_qty_sales) AS high_qty_sales,
    SUM(CASE WHEN sm.sm_type = 'AIR' THEN cr.cr_return_amount ELSE 0 END) AS air_return_amount,
    MIN(d.d_date) AS first_sale_date,
    MAX(d.d_date) AS last_sale_date
FROM ss_agg
JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE
    d.d_year = 2001
    AND s.s_state = 'CA'
    AND sm.sm_carrier = 'UPS'
    AND ca.ca_state = 'CA'
    AND cd.cd_gender = 'M'
    AND hd.hd_income_band_sk = 5
    AND cr.cr_return_amount > 0
GROUP BY
    s.s_store_name,
    d.d_year
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
