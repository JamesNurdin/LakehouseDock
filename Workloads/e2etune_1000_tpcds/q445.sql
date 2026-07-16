WITH sales_agg AS (
    SELECT
        ss_item_sk,
        SUM(ss_quantity) AS total_sold_qty,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_ext_discount_amt) AS total_discount_amt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451910 AND 2451915
    GROUP BY ss_item_sk
),
returns_agg AS (
    SELECT
        sr.sr_item_sk,
        r.r_reason_desc,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451910 AND 2451915
    GROUP BY sr.sr_item_sk, r.r_reason_desc
)
SELECT
    s.ss_item_sk,
    s.total_sold_qty,
    s.total_net_paid,
    s.total_discount_amt,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    CASE WHEN s.total_sold_qty > 0 THEN COALESCE(r.total_return_qty, 0) * 100.0 / s.total_sold_qty ELSE 0 END AS return_rate_pct,
    CASE WHEN s.total_net_paid > 0 THEN (s.total_net_paid - COALESCE(r.total_net_loss, 0)) / s.total_net_paid * 100.0 ELSE 0 END AS profit_margin_pct,
    r.r_reason_desc,
    RANK() OVER (PARTITION BY s.ss_item_sk ORDER BY COALESCE(r.total_return_qty, 0) DESC) AS return_qty_rank,
    PERCENT_RANK() OVER (ORDER BY CASE WHEN s.total_sold_qty > 0 THEN COALESCE(r.total_return_qty, 0) * 100.0 / s.total_sold_qty ELSE 0 END DESC) AS return_rate_pct_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.ss_item_sk = r.sr_item_sk
WHERE s.total_discount_amt > 500
ORDER BY s.total_net_paid DESC
LIMIT 10
