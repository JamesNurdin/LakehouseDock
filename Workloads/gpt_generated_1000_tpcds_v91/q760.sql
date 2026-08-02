WITH agg_returns AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand_id,
        i.i_category_id,
        d.d_date,
        c_refund.c_customer_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_quantity,
        AVG(cr.cr_fee) AS avg_fee,
        COUNT(*) AS return_cnt,
        ARRAY[i.i_brand_id, i.i_category_id] AS brand_category_arr
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c_refund
        ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer c_return
        ON cr.cr_returning_customer_sk = c_return.c_customer_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE
        cc.cc_state = 'CA'
        AND i.i_category_id = 4
        AND w.w_country = 'United States'
        AND d.d_year = 2001
        AND t.t_hour BETWEEN 8 AND 16
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand_id,
        i.i_category_id,
        d.d_date,
        c_refund.c_customer_sk
),
unnested AS (
    SELECT
        ar.*,
        bca.brand_category_id,
        SUM(ar.total_return_amount) OVER (PARTITION BY ar.cc_call_center_sk) AS sum_return_by_cc,
        (SELECT COUNT(*) FROM catalog_returns cr_sub WHERE cr_sub.cr_refunded_customer_sk = ar.c_customer_sk) AS total_refunds_for_customer
    FROM agg_returns ar
    CROSS JOIN UNNEST(ar.brand_category_arr) AS bca(brand_category_id)
    WHERE ar.total_return_amount > (
        SELECT AVG(cr3.cr_return_amount)
        FROM catalog_returns cr3
        WHERE cr3.cr_item_sk = ar.i_item_sk
    )
)
SELECT
    cc_call_center_sk,
    cc_name,
    i_item_id,
    i_product_name,
    d_date,
    c_customer_sk,
    total_return_amount,
    total_quantity,
    avg_fee,
    return_cnt,
    brand_category_id,
    sum_return_by_cc,
    total_refunds_for_customer,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_sk ORDER BY total_return_amount DESC) AS rn
FROM unnested
ORDER BY sum_return_by_cc DESC, total_return_amount DESC
LIMIT 100
