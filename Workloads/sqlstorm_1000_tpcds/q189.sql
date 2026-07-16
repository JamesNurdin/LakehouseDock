WITH
common_customers AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    INTERSECT
    SELECT ss.ss_customer_sk
    FROM store_sales ss
),
all_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_call_center_sk AS call_center_sk,
        NULL AS store_sk,
        NULL AS web_page_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt,
        cs.cs_ext_sales_price AS ext_sales_price,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        NULL,
        ss.ss_store_sk,
        NULL,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        NULL,
        NULL,
        ws.ws_web_page_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_ext_sales_price,
        'web' AS channel
    FROM web_sales ws
),
returns_all AS (
    SELECT
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        'store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_return_amt,
        wr.wr_net_loss,
        'web' AS channel
    FROM web_returns wr
),
monthly_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.customer_sk,
        s.channel,
        COALESCE(s.call_center_sk, 0) AS call_center_sk,
        COALESCE(s.store_sk, 0) AS store_sk,
        COALESCE(s.web_page_sk, 0) AS web_page_sk,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.discount_amt) AS total_discount,
        SUM(s.quantity) AS total_quantity,
        COUNT(*) AS txn_count,
        MAX(s.item_sk) AS sample_item_sk,
        MAX(s.promo_sk) AS sample_promo_sk
    FROM all_sales s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY
        d.d_year,
        d.d_month_seq,
        s.customer_sk,
        s.channel,
        COALESCE(s.call_center_sk, 0),
        COALESCE(s.store_sk, 0),
        COALESCE(s.web_page_sk, 0)
),
monthly_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.customer_sk,
        r.channel,
        SUM(r.return_amount) AS total_return_amount,
        SUM(r.net_loss) AS total_return_loss
    FROM returns_all r
    JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, r.customer_sk, r.channel
),
monthly_with_lag AS (
    SELECT
        ms.*,
        LAG(ms.total_net_profit) OVER (PARTITION BY ms.customer_sk, ms.channel ORDER BY ms.d_year, ms.d_month_seq) AS prev_month_profit,
        LAG(ms.total_net_paid) OVER (PARTITION BY ms.customer_sk, ms.channel ORDER BY ms.d_year, ms.d_month_seq) AS prev_month_sales
    FROM monthly_sales ms
),
customer_agg AS (
    SELECT
        mwl.d_year,
        mwl.d_month_seq,
        mwl.customer_sk,
        c.c_customer_id,
        mwl.channel,
        mwl.total_net_paid,
        mwl.total_net_profit,
        mwl.total_discount,
        mwl.total_quantity,
        mwl.txn_count,
        mwl.prev_month_profit,
        mwl.prev_month_sales,
        (mwl.total_net_profit - COALESCE(mwl.prev_month_profit, 0)) AS profit_change,
        CASE
            WHEN mwl.total_net_profit - COALESCE(mwl.prev_month_profit, 0) > 0 THEN 'Rising'
            WHEN mwl.total_net_profit - COALESCE(mwl.prev_month_profit, 0) < 0 THEN 'Falling'
            ELSE 'Stable'
        END AS profit_trend,
        COALESCE(mr.total_return_amount, 0) AS total_return_amount,
        COALESCE(mr.total_return_loss, 0) AS total_return_loss,
        (mwl.total_net_paid - COALESCE(mr.total_return_amount, 0)) AS net_paid_after_returns,
        (mwl.total_net_profit - COALESCE(mr.total_return_loss, 0)) AS net_profit_after_returns,
        COALESCE(cc.cc_name, 'N/A') AS call_center_name,
        COALESCE(p.p_promo_name, 'NoPromo') AS promo_name,
        CASE WHEN mwl.txn_count > 0 THEN mwl.total_discount / mwl.txn_count ELSE 0 END AS avg_discount_per_txn,
        CONCAT(c.c_customer_id, '-', CAST(mwl.d_year AS VARCHAR), '-', CAST(mwl.d_month_seq AS VARCHAR)) AS customer_period_key,
        COALESCE(CAST(cc.cc_gmt_offset AS VARCHAR), 'UNKNOWN') AS call_center_gmt_offset_str,
        (SELECT COUNT(DISTINCT ss2.ss_store_sk)
         FROM store_sales ss2
         JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
         WHERE ss2.ss_customer_sk = mwl.customer_sk
           AND d2.d_year = mwl.d_year
           AND d2.d_month_seq = mwl.d_month_seq) AS distinct_stores_visited
    FROM monthly_with_lag mwl
    LEFT JOIN monthly_returns mr
        ON mwl.d_year = mr.d_year
        AND mwl.d_month_seq = mr.d_month_seq
        AND mwl.customer_sk = mr.customer_sk
        AND mwl.channel = mr.channel
    LEFT JOIN customer c
        ON mwl.customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc
        ON mwl.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN promotion p
        ON mwl.sample_promo_sk = p.p_promo_sk
    WHERE mwl.customer_sk IN (SELECT customer_sk FROM common_customers)
),
ranked_customers AS (
    SELECT
        ca.*,
        DENSE_RANK() OVER (PARTITION BY ca.d_year ORDER BY ca.total_net_profit DESC) AS year_profit_rank,
        ROW_NUMBER() OVER (PARTITION BY ca.d_year ORDER BY ca.net_paid_after_returns DESC) AS year_sales_rank
    FROM customer_agg ca
)
SELECT
    rc.d_year,
    rc.d_month_seq,
    rc.c_customer_id,
    rc.channel,
    rc.total_net_paid,
    rc.total_net_profit,
    rc.avg_discount_per_txn,
    rc.profit_change,
    rc.profit_trend,
    rc.total_return_amount,
    rc.total_return_loss,
    rc.net_paid_after_returns,
    rc.net_profit_after_returns,
    rc.call_center_name,
    rc.promo_name,
    rc.customer_period_key,
    rc.call_center_gmt_offset_str,
    rc.distinct_stores_visited,
    rc.year_profit_rank,
    rc.year_sales_rank
FROM ranked_customers rc
WHERE rc.year_profit_rank <= 10
ORDER BY rc.d_year, rc.year_profit_rank, rc.channel
