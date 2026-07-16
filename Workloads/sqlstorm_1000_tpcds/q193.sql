WITH cte_sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d.d_year,
        d.d_quarter_name,
        cc.cc_name,
        CASE
            WHEN cs.cs_quantity = 0 THEN NULL
            ELSE cs.cs_net_paid / NULLIF(cs.cs_quantity, 0)
        END AS avg_price_per_qty,
        concat_ws('|', COALESCE(c.c_first_name, ''), COALESCE(c.c_last_name, ''), COALESCE(cc.cc_name, 'UNKNOWN')) AS composite_key,
        (
            SELECT SUM(cr.cr_return_quantity)
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = cs.cs_item_sk
              AND cr.cr_returning_customer_sk = c.c_customer_sk
              AND cr.cr_returned_date_sk = cs.cs_sold_date_sk
        ) AS total_return_quantity
    FROM catalog_sales cs
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_quantity > 0
      AND (cs.cs_net_paid IS NOT NULL OR cs.cs_net_profit IS NULL)
      AND d.d_year BETWEEN 1999 AND 2002
),
cte_returns AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        MAX(sr.sr_return_quantity) AS max_return_qty_per_transaction,
        ROW_NUMBER() OVER (PARTITION BY sr.sr_customer_sk ORDER BY sr.sr_returned_date_sk DESC) AS rn
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_customer_sk, sr.sr_item_sk
    HAVING SUM(sr.sr_return_quantity) > 0
),
cte_combined AS (
    SELECT
        s.date_sk,
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.cs_item_sk,
        COALESCE(s.cs_quantity, 0) AS qty_sold,
        COALESCE(s.cs_net_paid, 0) AS net_paid,
        COALESCE(s.cs_net_profit, 0) AS net_profit,
        r.total_return_qty,
        r.total_return_amt,
        s.composite_key,
        CASE WHEN r.rn = 1 THEN TRUE ELSE FALSE END AS most_recent_return_flag,
        RANK() OVER (PARTITION BY s.c_customer_sk ORDER BY s.cs_net_paid DESC NULLS LAST) AS profit_rank,
        cc.cc_call_center_sk
    FROM cte_sales s
    LEFT JOIN cte_returns r
        ON s.c_customer_sk = r.customer_sk
        AND s.cs_item_sk = r.item_sk
    LEFT JOIN call_center cc
        ON s.cc_name = cc.cc_name
    WHERE (s.total_return_quantity IS NULL OR s.total_return_quantity = 0)
),
final_set AS (
    SELECT
        date_sk,
        c_customer_sk,
        composite_key,
        qty_sold,
        net_paid,
        net_profit,
        total_return_qty,
        total_return_amt,
        profit_rank,
        most_recent_return_flag,
        CASE
            WHEN qty_sold = 0 THEN NULL
            ELSE (net_profit - COALESCE(total_return_amt, 0)) / NULLIF(qty_sold, 0)
        END AS profit_per_unit_adjusted,
        regexp_like(composite_key, '\\d') AS composite_has_digit,
        CASE WHEN cc_call_center_sk IS NULL THEN 'MISSING_CC' ELSE 'HAS_CC' END AS cc_status
    FROM cte_combined
),
top_rows AS (
    SELECT *
    FROM final_set
    WHERE profit_per_unit_adjusted > 0
      AND composite_has_digit = TRUE
      AND cc_status = 'HAS_CC'
    ORDER BY profit_per_unit_adjusted DESC
    LIMIT 100
)
SELECT *
FROM top_rows
UNION ALL
SELECT
    NULL AS date_sk,
    NULL AS c_customer_sk,
    'SUMMARY' AS composite_key,
    NULL AS qty_sold,
    SUM(net_paid) AS net_paid,
    SUM(net_profit) AS net_profit,
    NULL AS total_return_qty,
    NULL AS total_return_amt,
    NULL AS profit_rank,
    NULL AS most_recent_return_flag,
    NULL AS profit_per_unit_adjusted,
    NULL AS composite_has_digit,
    NULL AS cc_status
FROM final_set
WHERE profit_per_unit_adjusted IS NOT NULL
GROUP BY
    date_sk,
    c_customer_sk,
    composite_key,
    qty_sold,
    total_return_qty,
    total_return_amt,
    profit_rank,
    most_recent_return_flag,
    profit_per_unit_adjusted,
    composite_has_digit,
    cc_status
