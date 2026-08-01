WITH
agg1 AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_size,
        i.i_formulation,
        hd.hd_income_band_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(sr.sr_return_amt) AS total_store_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
    FROM
        item i
        JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
                              AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                               AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                         AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE
        i.i_size = 'large'
        AND i.i_formulation LIKE '%goldenrod%'
        AND cc.cc_gmt_offset > -5
        AND ws.ws_net_paid > 1000
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_size,
        i.i_formulation,
        hd.hd_income_band_sk
),
top_reason_per_item AS (
    SELECT
        i.i_item_id,
        tr.reason_desc,
        tr.cnt
    FROM
        item i
        CROSS JOIN LATERAL (
            SELECT
                r.r_reason_desc AS reason_desc,
                COUNT(*) AS cnt
            FROM
                store_returns sr
                JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
            WHERE
                sr.sr_item_sk = i.i_item_sk
            GROUP BY
                r.r_reason_desc
            ORDER BY
                cnt DESC
            LIMIT 1
        ) tr
),
full_join_sales_returns AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price AS sales_price,
        sr.sr_return_amt AS return_amt
    FROM
        store_sales ss
        FULL OUTER JOIN store_returns sr
            ON sr.sr_item_sk = ss.ss_item_sk
           AND sr.sr_ticket_number = ss.ss_ticket_number
),
intersect_items AS (
    SELECT i_item_id FROM agg1 WHERE total_store_sales > 10000
    INTERSECT
    SELECT i_item_id FROM agg1 WHERE total_web_sales > 8000
),
final_agg AS (
    SELECT
        a.i_item_sk,
        a.i_item_id,
        a.i_brand,
        a.i_size,
        a.i_formulation,
        a.total_store_sales,
        a.total_web_sales,
        a.total_catalog_returns,
        a.total_store_returns,
        a.store_ticket_cnt,
        a.web_order_cnt,
        tr.reason_desc,
        fjs.sales_price,
        fjs.return_amt,
        ROW_NUMBER() OVER (PARTITION BY a.i_brand ORDER BY a.total_store_sales DESC) AS brand_rank,
        (
            SELECT MAX(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = a.i_item_sk
        ) AS max_return_amount
    FROM
        agg1 a
        LEFT JOIN top_reason_per_item tr ON tr.i_item_id = a.i_item_id
        LEFT JOIN full_join_sales_returns fjs ON fjs.ss_item_sk = a.i_item_sk
    WHERE
        a.i_item_id IN (SELECT i_item_id FROM intersect_items)
        AND a.total_store_returns > 500
        AND a.total_catalog_returns < 2000
        AND a.store_ticket_cnt >= 5
        AND a.web_order_cnt <= 20
)
SELECT
    i_item_sk,
    i_item_id,
    i_brand,
    i_size,
    i_formulation,
    total_store_sales,
    total_web_sales,
    total_catalog_returns,
    total_store_returns,
    store_ticket_cnt,
    web_order_cnt,
    reason_desc,
    sales_price,
    return_amt,
    brand_rank,
    max_return_amount
FROM final_agg
ORDER BY brand_rank, i_item_id
