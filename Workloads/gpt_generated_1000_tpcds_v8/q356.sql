WITH sampled_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
),
item_desc_words AS (
    SELECT i.i_item_sk,
           word
    FROM item i
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
),
latest_return AS (
    SELECT cr.cr_item_sk,
           MAX(d.d_date) AS latest_return_date
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_item_sk
)
SELECT
    s.s_store_name,
    w.w_city,
    i.i_item_id,
    i.i_brand,
    r.r_reason_desc,
    SUM(ss.ss_ext_sales_price)                     AS total_sales,
    AVG(ss.ss_ext_sales_price)                     AS avg_sales,
    COUNT(DISTINCT ss.ss_ticket_number)            AS num_transactions,
    MIN(ss.ss_sales_price)                         AS min_price,
    MAX(ss.ss_sales_price)                         AS max_price,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank,
    lr.latest_return_date,
    lt.recent_tickets
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN sampled_inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_date_sk = d.d_date_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN LATERAL (
    SELECT array_agg(ss2.ss_ticket_number) AS recent_tickets
    FROM store_sales ss2
    WHERE ss2.ss_store_sk = s.s_store_sk
      AND ss2.ss_sold_date_sk = d.d_date_sk
      AND ss2.ss_sold_time_sk > t.t_time_sk - 1000
    LIMIT 10
) lt ON true
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                        AND cr.cr_returned_date_sk = d.d_date_sk
                        AND cr.cr_returned_time_sk = t.t_time_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN latest_return lr ON lr.cr_item_sk = i.i_item_sk
LEFT JOIN item_desc_words idw ON idw.i_item_sk = i.i_item_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND i.i_brand = 'BrandX'
  AND w.w_city = 'Riverside'
  AND ib.ib_lower_bound >= 50000
GROUP BY ROLLUP(
    s.s_store_name,
    w.w_city,
    i.i_item_id,
    i.i_brand,
    r.r_reason_desc,
    lr.latest_return_date,
    lt.recent_tickets
)
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
