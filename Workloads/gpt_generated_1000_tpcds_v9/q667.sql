WITH warehouse_returns AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        w.w_street_name,
        COUNT(cr.cr_order_number) AS return_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM tpcds.catalog_returns cr
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_street_name LIKE '%Park%'
       OR w.w_street_name LIKE '%Broadway%'
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        w.w_street_name
)
SELECT
    wr.w_warehouse_id,
    SUBSTRING(wr.w_warehouse_id, 9, 1) AS region_code,
    REGEXP_EXTRACT(wr.w_warehouse_id, '^AAAAAAA(.).+', 1) AS region_code_extracted,
    CONCAT(wr.w_city, ', ', wr.w_state) AS city_state,
    wr.w_street_name,
    REGEXP_EXTRACT(wr.w_street_name, '(\\w+)$', 1) AS street_name_last_word,
    wr.return_cnt,
    wr.total_return_amount,
    wr.total_return_amount / wr.return_cnt AS avg_return_amount,
    ROW_NUMBER() OVER (ORDER BY wr.total_return_amount DESC) AS return_amount_rank,
    SUM(wr.total_return_amount) OVER () AS total_return_amount_all_warehouses
FROM warehouse_returns wr
WHERE REGEXP_LIKE(wr.w_warehouse_id, '^AAAAAAA[AE]')
  AND wr.w_city LIKE 'A%'
ORDER BY wr.total_return_amount DESC
LIMIT 100
