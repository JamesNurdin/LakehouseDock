WITH catalog_agg AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk AS customer_sk,
        cc.cc_market_manager,
        SUM(cr.cr_return_amount) AS total_cr_return_amount,
        SUM(cr.cr_return_tax) AS total_cr_return_tax,
        COUNT(*) AS cr_return_cnt,
        CASE WHEN SUM(cr.cr_return_amount) > 500 THEN 'High' ELSE 'Low' END AS return_level
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cc.cc_market_manager = 'Kim Wilson'
      AND c.c_birth_country = 'CHILE'
      AND cr.cr_return_ship_cost > 100
    GROUP BY cr.cr_item_sk, cr.cr_refunded_customer_sk, cc.cc_market_manager
),
store_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_customer_sk AS customer_sk,
        SUM(sr.sr_return_amt) AS total_sr_return_amt,
        SUM(sr.sr_return_tax) AS total_sr_return_tax,
        COUNT(*) AS sr_return_cnt,
        CASE WHEN SUM(sr.sr_return_amt) > 300 THEN 'High' ELSE 'Low' END AS return_level
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month = 12
      AND i.i_category = 'Electronics'
    GROUP BY sr.sr_item_sk, sr.sr_customer_sk
),
combined AS (
    SELECT
        COALESCE(ca.cr_item_sk, sa.sr_item_sk) AS item_sk,
        COALESCE(ca.customer_sk, sa.customer_sk) AS customer_sk,
        ca.cc_market_manager,
        ca.total_cr_return_amount,
        ca.total_cr_return_tax,
        ca.cr_return_cnt,
        ca.return_level AS cr_return_level,
        sa.total_sr_return_amt,
        sa.total_sr_return_tax,
        sa.sr_return_cnt,
        sa.return_level AS sr_return_level
    FROM catalog_agg ca
    FULL OUTER JOIN store_agg sa
        ON ca.cr_item_sk = sa.sr_item_sk
       AND ca.customer_sk = sa.customer_sk
),
web_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid) AS total_ws_net_paid,
        SUM(ws.ws_ext_sales_price) AS total_ws_sales_price,
        COUNT(*) AS ws_order_cnt,
        CASE WHEN SUM(ws.ws_net_paid) > 1000 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_level
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_ship_mode_sk IS NOT NULL
    GROUP BY ws.ws_item_sk, ws.ws_bill_customer_sk
),
final_agg AS (
    SELECT
        COALESCE(c.item_sk, w.ws_item_sk) AS item_sk,
        COALESCE(c.customer_sk, w.customer_sk) AS customer_sk,
        c.cc_market_manager,
        c.total_cr_return_amount,
        c.total_sr_return_amt,
        w.total_ws_net_paid,
        c.cr_return_cnt,
        c.sr_return_cnt,
        w.ws_order_cnt,
        CASE
            WHEN c.total_cr_return_amount IS NULL THEN 'Only Store Return'
            WHEN c.total_sr_return_amt IS NULL THEN 'Only Catalog Return'
            ELSE 'Both Returns'
        END AS return_source,
        (COALESCE(c.total_cr_return_amount, 0) + COALESCE(c.total_sr_return_amt, 0) + COALESCE(w.total_ws_net_paid, 0)) AS total_combined_amount,
        (COALESCE(c.cr_return_cnt, 0) + COALESCE(c.sr_return_cnt, 0) + COALESCE(w.ws_order_cnt, 0)) AS total_activity_cnt
    FROM combined c
    LEFT JOIN web_agg w
        ON c.item_sk = w.ws_item_sk
       AND c.customer_sk = w.customer_sk
)
SELECT
    CASE
        WHEN total_cr_return_amount IS NULL THEN 'Only Store Return'
        WHEN total_sr_return_amt IS NULL THEN 'Only Catalog Return'
        ELSE 'Both Returns'
    END AS return_source,
    COUNT(*) AS cnt_rows,
    AVG(total_combined_amount) AS avg_total_combined_amount,
    SUM(total_combined_amount) AS sum_total_combined_amount
FROM final_agg
WHERE total_combined_amount > 300
  AND cc_market_manager = 'Kim Wilson'
  AND total_activity_cnt >= 2
GROUP BY CASE
        WHEN total_cr_return_amount IS NULL THEN 'Only Store Return'
        WHEN total_sr_return_amt IS NULL THEN 'Only Catalog Return'
        ELSE 'Both Returns'
    END
ORDER BY sum_total_combined_amount DESC
LIMIT 100
