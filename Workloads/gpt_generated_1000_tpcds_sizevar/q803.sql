WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_time_sk,
        SUM(ss_ext_sales_price) AS store_sales_total,
        COUNT(*) AS store_sales_cnt,
        AVG(ss_ext_sales_price) AS avg_store_sale,
        MAX(ss_ext_sales_price) AS max_store_sale
    FROM store_sales
    WHERE ss_quantity >= 2
    GROUP BY ss_store_sk, ss_sold_time_sk
),
joined AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        cp.cp_department,
        r.r_reason_desc,
        td.t_hour,
        ws.ws_list_price,
        ss_agg.store_sales_total,
        ss_agg.store_sales_cnt,
        cr.cr_return_amount,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS return_amount_category,
        dr.rate AS discount_rate,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cr.cr_return_amount DESC) AS rn
    FROM ss_agg
    JOIN store s
        ON ss_agg.ss_store_sk = s.s_store_sk
    JOIN time_dim td
        ON ss_agg.ss_sold_time_sk = td.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    CROSS JOIN (VALUES (0.0), (0.1), (0.2)) AS dr(rate)
    WHERE s.s_state = 'CA'
      AND s.s_city = 'Los Angeles'
      AND td.t_hour BETWEEN 9 AND 17
      AND cp.cp_department = 'Electronics'
      AND r.r_reason_desc LIKE '%damaged%'
      AND ws.ws_list_price > 50
      AND cr.cr_return_amount > 10
)
SELECT
    s_store_id,
    s_city,
    s_state,
    cp_department,
    r_reason_desc,
    t_hour,
    ws_list_price,
    store_sales_total,
    store_sales_cnt,
    cr_return_amount,
    return_amount_category,
    discount_rate,
    rn
FROM joined
WHERE rn <= 3
ORDER BY s_store_id, rn
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
