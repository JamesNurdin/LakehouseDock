WITH sales_returns AS (
    SELECT
        cs.cs_sold_date_sk                                              AS date_sk,
        cs.cs_sold_time_sk                                              AS time_sk,
        cs.cs_item_sk                                                   AS item_sk,
        cs.cs_call_center_sk                                            AS call_center_sk,
        cs.cs_bill_addr_sk                                              AS address_sk,
        cs.cs_net_paid                                                  AS net_amount,
        CAST(NULL AS INTEGER)                                           AS reason_sk,
        'sale'                                                          AS src
    FROM catalog_sales cs
    UNION ALL
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_refunded_addr_sk,
        -cr.cr_return_amount                                            AS net_amount,
        cr.cr_reason_sk,
        'return'                                                         AS src
    FROM catalog_returns cr
),
agg AS (
    SELECT
        cc.cc_name                               AS call_center_name,
        s.s_store_name                           AS store_name,
        d_store.d_year                           AS year,
        r.r_reason_desc                          AS return_reason_desc,
        SUM(sr.net_amount)                       AS total_net_amount,
        COUNT(*)                                 AS transaction_count
    FROM sales_returns sr
    JOIN date_dim d_sales ON sr.date_sk = d_sales.d_date_sk
    JOIN time_dim t ON sr.time_sk = t.t_time_sk
    JOIN item i ON sr.item_sk = i.i_item_sk
    JOIN call_center cc ON sr.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN reason r ON sr.reason_sk = r.r_reason_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN date_dim d_store ON ss.ss_sold_date_sk = d_store.d_date_sk
    JOIN time_dim t_store ON ss.ss_sold_time_sk = t_store.t_time_sk
    JOIN item i_store ON ss.ss_item_sk = i_store.i_item_sk
    JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_date_sk = d_store.d_date_sk
                      AND inv.inv_item_sk = i_store.i_item_sk
    WHERE EXISTS (
        SELECT 1
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
          AND inv2.inv_quantity_on_hand > 0
    )
    GROUP BY
        cc.cc_name,
        s.s_store_name,
        d_store.d_year,
        r.r_reason_desc
)
SELECT
    call_center_name,
    store_name,
    year,
    return_reason_desc,
    total_net_amount,
    transaction_count,
    CASE WHEN total_net_amount > 100000 THEN 'high' ELSE 'normal' END AS revenue_category
FROM agg
ORDER BY total_net_amount DESC
LIMIT 100
