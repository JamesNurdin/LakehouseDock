WITH agg AS (
    SELECT
        cc.cc_call_center_sk,
        d_sold.d_year,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_return_loss,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN (
        SELECT sr.*, d_ret.d_year AS return_year
        FROM store_returns sr
        JOIN date_dim d_ret
            ON sr.sr_returned_date_sk = d_ret.d_date_sk
    ) sr
        ON sr.sr_reason_sk = r.r_reason_sk
        AND sr.return_year = d_sold.d_year
    WHERE d_sold.d_year = 2001
      AND cc.cc_employees BETWEEN 1500000 AND 4000000
      AND cc.cc_market_manager IN ('Julius Durham', 'Mark Jimenez')
      AND cc.cc_gmt_offset > -5.00
      AND cs.cs_ext_discount_amt < 2000.00
      AND cs.cs_quantity > 1
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
              AND cr2.cr_return_amount > 5000
      )
    GROUP BY cc.cc_call_center_sk, d_sold.d_year
),
avg_profit AS (
    SELECT AVG(total_profit) AS avg_total_profit FROM agg
)
SELECT
    agg.cc_call_center_sk,
    agg.d_year,
    agg.total_sales,
    agg.total_quantity,
    agg.total_profit,
    agg.total_catalog_return_loss,
    agg.total_store_return_loss,
    (agg.total_profit - (agg.total_catalog_return_loss + agg.total_store_return_loss)) AS net_contribution,
    avg_profit.avg_total_profit
FROM agg
CROSS JOIN avg_profit
WHERE agg.total_sales > 10000
ORDER BY net_contribution DESC
LIMIT 100
