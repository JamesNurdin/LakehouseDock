WITH filtered_returns AS (
    SELECT
        cr_warehouse_sk,
        cr_reason_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_return_tax,
        cr_return_ship_cost,
        cr_refunded_cash,
        cr_net_loss,
        cr_returning_customer_sk
    FROM catalog_returns
    WHERE cr_return_quantity > 1
      AND cr_return_amount BETWEEN 10 AND 500
      AND cr_return_tax > 20
),
agg AS (
    SELECT
        w.w_warehouse_name,
        r.r_reason_desc,
        COUNT(*) AS return_cnt,
        SUM(fr.cr_return_amount) AS total_return_amount,
        AVG(fr.cr_return_amount) AS avg_return_amount,
        MIN(fr.cr_return_amount) AS min_return_amount,
        MAX(fr.cr_return_amount) AS max_return_amount,
        SUM(fr.cr_return_tax) AS total_tax
    FROM filtered_returns fr
    JOIN warehouse w
        ON fr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON fr.cr_reason_sk = r.r_reason_sk
    WHERE w.w_country = 'United States'
      AND w.w_street_type IN ('Dr.', 'Ave', 'Road')
      AND r.r_reason_desc LIKE '%Did not%'
    GROUP BY w.w_warehouse_name, r.r_reason_desc
    HAVING SUM(fr.cr_return_amount) > 1000
)
SELECT
    a.w_warehouse_name,
    a.r_reason_desc,
    a.return_cnt,
    a.total_return_amount,
    a.avg_return_amount,
    a.min_return_amount,
    a.max_return_amount,
    a.total_tax,
    RANK() OVER (PARTITION BY a.w_warehouse_name ORDER BY a.total_return_amount DESC) AS rank_per_warehouse
FROM agg a
ORDER BY a.total_return_amount DESC
LIMIT 100
