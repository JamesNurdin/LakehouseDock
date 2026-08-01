/*
Goal: Summarize yearly return and sales performance per call center and store, including an item‑level breakdown via UNNEST. The query uses a left join for stores, applies three filter predicates, incorporates an EXISTS subquery, aggregates with a CUBE for subtotals, and limits the result set.
*/
WITH base_agg AS (
    SELECT
        d.d_year,
        cc.cc_name,
        s.s_store_name,
        ca_refund.ca_gmt_offset,
        r.r_reason_desc,
        sm.sm_ship_mode_id,
        SUM(cr.cr_return_amount)                AS total_return_amount,
        SUM(ws.ws_net_paid)                     AS total_net_paid,
        AVG(ws.ws_ext_discount_amt)             AS avg_discount,
        COUNT(DISTINCT ws.ws_item_sk)           AS distinct_items_sold,
        ARRAY_AGG(DISTINCT ws.ws_item_sk)       AS items_array
    FROM date_dim d
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_end_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN household_demographics hd_refund
        ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    WHERE d.d_year = 2001
      AND ca_refund.ca_gmt_offset BETWEEN -7.00 AND -5.00
      AND (s.s_zip LIKE '4%' OR s.s_zip IS NULL)
      AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
      AND EXISTS (
          SELECT 1 FROM catalog_returns cr2 WHERE cr2.cr_order_number = ws.ws_order_number
      )
    GROUP BY
        d.d_year,
        cc.cc_name,
        s.s_store_name,
        ca_refund.ca_gmt_offset,
        r.r_reason_desc,
        sm.sm_ship_mode_id
)
SELECT
    b.d_year,
    b.cc_name,
    b.s_store_name,
    SUM(b.total_return_amount)   AS sum_return_amount,
    SUM(b.total_net_paid)        AS sum_net_paid,
    AVG(b.avg_discount)          AS avg_discount,
    SUM(b.distinct_items_sold)   AS sum_distinct_items,
    COUNT(u.item_sk)             AS total_unnested_items
FROM base_agg b
CROSS JOIN UNNEST(b.items_array) AS u(item_sk)
GROUP BY CUBE(b.d_year, b.cc_name, b.s_store_name)
HAVING SUM(b.total_return_amount) > 0
ORDER BY b.d_year, b.cc_name, b.s_store_name
LIMIT 100
