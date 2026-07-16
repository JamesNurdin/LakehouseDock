WITH sales_summary AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        SUM(cs_net_paid) AS total_sales_net_paid,
        SUM(cs_quantity) AS total_sales_qty,
        AVG(cs_ext_discount_amt) AS avg_discount_amt
    FROM catalog_sales
    WHERE cs_ext_discount_amt > 0
    GROUP BY cs_item_sk, cs_order_number
),
joined AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_reason_sk,
        cr.cr_net_loss,
        ss.total_sales_net_paid,
        ss.avg_discount_amt
    FROM catalog_returns cr
    JOIN sales_summary ss
        ON cr.cr_item_sk = ss.cs_item_sk
       AND cr.cr_order_number = ss.cs_order_number
    WHERE cr.cr_net_loss > 1000
),
aggregated AS (
    SELECT
        cr_item_sk,
        cr_reason_sk,
        COUNT(*) AS return_cnt,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(total_sales_net_paid) AS total_sales_net_paid,
        AVG(avg_discount_amt) AS avg_sales_discount
    FROM joined
    GROUP BY cr_item_sk, cr_reason_sk
    HAVING COUNT(*) >= 3
)
SELECT
    cr_item_sk,
    cr_reason_sk,
    return_cnt,
    total_net_loss,
    total_sales_net_paid,
    avg_sales_discount,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100
